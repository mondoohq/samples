#!/bin/sh

sudo apt update && sudo apt remove -y netcat-openbsd && sudo apt install -y netcat-traditional jq
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose

sudo usermod -a -G docker ubuntu

sudo apt install -y uidmap
dockerd-rootless-setuptool.sh uninstall --force

wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube

minikube version

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

echo "ubuntu:${pass_string}" | sudo chpasswd
sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
systemctl restart sshd

curl -ko /home/ubuntu/dvwa-deployment.yaml https://raw.githubusercontent.com/Lunalectric/container-escape/main/assets/dvwa-deployment.yml
