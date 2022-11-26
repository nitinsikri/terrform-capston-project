#!/bin/bash

yum update -y
yum update httpd -y
echo "Hello server 1" > /var/www/html/index.html
service httpd start