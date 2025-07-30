#!/bin/bash
yum update -y
yum install -y httpd php php-mysqli
systemctl start httpd
systemctl enable httpd
echo "<?php phpinfo(); ?>" > /var/www/html/index.php
