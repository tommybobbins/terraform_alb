#!/bin/sh
sudo amazon-linux-extras install -y nginx1
sudo systemctl enable nginx --now
echo "<h1>Hello Bobbins!</h1>" | sudo tee /usr/share/nginx/html/index.html
