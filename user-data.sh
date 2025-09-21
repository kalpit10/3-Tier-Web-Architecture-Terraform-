#!/bin/bash
yum update -y
# jq to parse JSON, amazon-cloudwatch-agent for monitoring
yum install -y httpd php php-mysqli jq mariadb105
yum install -y amazon-cloudwatch-agent

# Create CloudWatch Agent config directory
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

systemctl start httpd
systemctl enable httpd

# Add a wait loop to ensure EC2 metadata and IAM role are ready
# Get instance ID using IMDSv2
for i in {1..5}; do
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
    -s)
  
  if [[ ! -z "$TOKEN" ]]; then
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
      -s http://169.254.169.254/latest/meta-data/instance-id)
  fi
  
  if [[ ! -z "$INSTANCE_ID" ]]; then
    echo "Instance ID obtained: $INSTANCE_ID"
    break
  fi
  echo "Waiting for metadata service... attempt $i"
  sleep 5
done


# Save CloudWatch Agent config to a file
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
${cloudwatch_agent_config}
EOF

# Start the CloudWatch Agent (retry logic)
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s




# -----------------------------
# Step: Get DB credentials from Secrets Manager
# -----------------------------
# Ask AWS Secrets Manager for the secret called "rds-db-credentials".
# This command pulls the latest value (a JSON string) into a variable.
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id rds-db-credentials \
  --query SecretString \
  --output text \
  --region us-east-1)

# The secret comes back as JSON text. Example:
# {"username":"mydbuser","password":"mypassword","dbname":"myappdb"}
# We use 'jq' to pick out each field and store it in shell variables.
DB_USER=$(echo $SECRET_JSON | jq -r .username)
DB_PASS=$(echo $SECRET_JSON | jq -r .password)
DB_NAME=$(echo $SECRET_JSON | jq -r .dbname)

# The DB host (the RDS endpoint) is not inside the secret.
# Terraform will fill in the right endpoint at runtime using ${DB_HOST}.
DB_HOST="${DB_HOST}"

# Now write these values into a PHP file that our web app can include.
# This way the PHP app doesn't need to know AWS CLI—it just "require()s" this file.
# The values are injected safely at boot instead of being hard-coded.
# using \ before $ to read the variable value (LHS) in php file. Otherwise it will not take the LHS value.
cat > /var/www/html/db.php <<EOF
<?php
\$db_host = "${DB_HOST}";
\$db_user = "$${DB_USER}";
\$db_pass = "$${DB_PASS}";
\$db_name = "$${DB_NAME}";
?>
EOF





# -----------------------------
# Main PHP application
# -----------------------------
cat << 'EOF' > /var/www/html/index.php
<?php
header("Content-Type: text/html");

// Get EC2 Instance ID using IMDSv2
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "http://169.254.169.254/latest/api/token");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ["X-aws-ec2-metadata-token-ttl-seconds: 21600"]);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PUT");
$token = curl_exec($ch);
curl_close($ch);

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "http://169.254.169.254/latest/meta-data/instance-id");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ["X-aws-ec2-metadata-token: $token"]);
$instance_id = curl_exec($ch);
curl_close($ch);

// Load DB credentials
require '/var/www/html/db.php';   // absolute path


// MySQL connection
// This uses the variables defined in db.php
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Insert form data
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $name = $_POST["name"];
    $email = $_POST["email"];
    $sql = "INSERT INTO users (name, email) VALUES ('$name', '$email')";
    if ($conn->query($sql) === TRUE) {
        $message = "<p class='success'>✅ Record inserted successfully!</p>";
    } else {
        $message = "<p class='error'>❌ Error: " . $conn->error . "</p>";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>3-Tier Web Application</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f3f3f3; padding: 40px; }
        .container { background-color: white; padding: 20px 30px; border-radius: 8px; max-width: 500px; margin: auto; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        h2 { color: #2c3e50; margin-bottom: 10px; }
        form { margin-top: 20px; }
        label, input { display: block; margin-bottom: 10px; width: 100%; }
        input[type="text"], input[type="email"] { padding: 8px; border: 1px solid #ccc; border-radius: 4px; }
        input[type="submit"] { background-color: #3498db; color: white; border: none; padding: 10px 15px; border-radius: 4px; cursor: pointer; }
        input[type="submit"]:hover { background-color: #2980b9; }
        .success { color: green; }
        .error { color: red; }
        .meta { margin-top: 20px; font-size: 14px; color: #555; }
    </style>
</head>
<body>
    <div class="container">
        <h2>💻 Hello from EC2 Instance</h2>
        <p class="meta">Instance ID: <strong><?php echo $instance_id; ?></strong></p>
        <?php if (isset($message)) echo $message; ?>
        <form method="post">
            <label>Name:</label>
            <input type="text" name="name" required>
            <label>Email:</label>
            <input type="email" name="email" required>
            <input type="submit" value="Submit">
        </form>
    </div>
</body>
</html>
EOF

# -----------------------------
# Healthcheck PHP script
# The load balancer will call this to check if the app is healthy. 
# Checking it via /index.php could give false negatives sometimes and make our LB think the app is unhealthy.
# -----------------------------
cat << 'EOF' > /var/www/html/healthcheck.php
<?php
// Load DB credentials
require 'db.php';

// Simple DB connection test
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

if ($conn->connect_error) {
    http_response_code(500);
    echo "DB connection failed";
    exit;
}

http_response_code(200);
echo "OK";
?>
EOF

chmod 644 /var/www/html/index.php /var/www/html/db.php /var/www/html/healthcheck.php
chown apache:apache /var/www/html/index.php /var/www/html/db.php /var/www/html/healthcheck.php
