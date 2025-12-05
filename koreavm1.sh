#!/bin/bash

sudo apt update 
sudo apt upgrade -y 

sudo apt install apache2 -y

sudo echo 'korea vm1
<a href="/upload/index.html">
  <button>Upload</button>
</a>' > /var/www/html/index.html

sudo systemctl enable apache2
sudo systemctl restart apache2