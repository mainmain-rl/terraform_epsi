#!/bin/bash
sudo apt update -y
sudo apt install docker docker.io -y
systemctl enable docker
service docker start
mkdir /home/html && touch /home/html/index.html
cat <<EOF > /home/html/index.html
<html>
<body>
<h1>Hello Lajeunesse Romain</h1>
<p>hostname is: $(hostname)</p>
</body>
</html>
EOF
docker run --name nginx -p 80:80 -v /home/html:/usr/share/nginx/html -d nginx