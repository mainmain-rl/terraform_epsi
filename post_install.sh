#!/bin/bash
sudo apt update -y
sudo apt install docker git docker.io -y
systemctl enable docker
service docker start
git clone https://github.com/MisterPurl/lab1.tsunamirr.com.git
docker run --name nginx -p 80:80 -v /home/lab1.tsunamirr.com:/usr/share/nginx/html -d nginx