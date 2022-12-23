#!/bin/bash
sudo apt update
sudo apt install apache2
echo "<h1>Welcome to Naveen Wijeyasekaran's website"  >  /var/www/html/index.html
sudo systemctl start apache2
sudo systemctl enable apache2