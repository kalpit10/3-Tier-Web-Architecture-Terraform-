#!/bin/bash
yum update -y
yum install -y httpd php php-mysqli

systemctl start httpd
systemctl enable httpd

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

// MySQL connection
$conn = new mysqli("finalprojectdb.cvhvyymhcwar.us-east-1.rds.amazonaws.com", "admin", "SenecaCAA100", "finalprojectdb");

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

chmod 644 /var/www/html/index.php
chown apache:apache /var/www/html/index.php
