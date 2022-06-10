#!/bin/sh

sudo apt update && sudo apt remove -y netcat-openbsd && sudo apt install -y netcat-traditional
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

cat <<- EOF > /home/ubuntu/dvwa-minikube-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dvwa-container-escape
  namespace: default
spec:
  selector:
    matchLabels:
      app: dvwa-container-escape
  template:
    metadata:
      labels:
        app: dvwa-container-escape
    spec:
      containers:
        - name: dvwa
          image: public.ecr.aws/x6s5a8t7/dvwa:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          securityContext:
            privileged: true
      terminationGracePeriodSeconds: 30
EOF
