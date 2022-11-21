#!/bin/bash

apt update
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common git
# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y docker-ce
groupadd docker
usermod -aG docker ubuntu

#install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.28.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#install sonarqube
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
git clone https://github.com/wlopezob/cloudformation.git
docker-compose -f cloudformation/sonarqube/docker-compose-postgres-example.yml  up -d