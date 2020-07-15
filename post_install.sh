#!/bin/bash
sudo apt update -y
sudo apt install docker docker.io -y
systemctl enable docker
service docker start
docker run --name nginx -p 80:80 -d nginx