#!/usr/bin/env bash

sudo apt-get install -y nginx
sudo apt-get install -y awscli
echo "<h1>Welcome to Grandpa's Whiskey-$HOSTNAME</h1>" | sudo tee /var/www/html/index.html
sudo systemctl start nginx
sudo systemctl enable nginx