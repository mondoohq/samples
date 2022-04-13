# DVWA EKS Provisioning

This folder contains Terraform automation code to provision the following:

- **AWS VPC**
- **AWS EKS Cluster** - 2 worker managed nodes (m5.medium)
- **Kali Linux AWS EC2 Instance** - Kali Linux for ethical hacking


<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [DVWA EKS Provisioning](#dvwa-eks-provisioning)
    - [Prerequsites](#prerequsites)
  - [Configuration](#configuration)
    - [Example configuration](#example-configuration)
  - [Provision the cluster](#provision-the-cluster)
  - [Connect to the cluster](#connect-to-the-cluster)
  - [Kali Linux](#kali-linux)

<!-- /code_chunk_output -->



### Prerequsites

- [AWS Account](https://aws.amazon.com/free/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) - `~> aws-cli/2.4.28`
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) - `~> v1.0.5`
- [AWS EC2 Key Pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html) - You should already have an AWS key pair created and uploaded to the region where you want to provision.

## Configuration

Before provisioning set the following environment variables:

- `TF_VAR_region` - AWS region where you want to provision the cluster.
- `TF_VAR_demo_name` - This is a prefix that will be applied to all provisioned resources (i.e. `your_name`).
- `TF_VAR_ssh_key` - AWS EC2 key pair for Kali linux access.
- `TF_VAR_publicIP` - IP address of your home network to be applied to the security group for the Kali linux instance.

### Example configuration 

Open a terminal and run the following commands:

```bash
export TF_VAR_region=us-east-1

export TF_VAR_demo_name=my_demo

export TF_VAR_ssh_key=aws_key

export TF_VAR_publicIP="73.231.132.25"
```

## Provision the cluster

1. Clone the project
```bash title="Clone the project"
git clone git@github.com:mondoohq/demos.git
```

2. cd into the terraform folder
```
cd demos/container-escape/terraform/aws
```

3. Initialize the project (download modules)

```
terraform init
```

4. Check that everything is ready

```
terraform plan
```

5. Apply the configuration

```
terraform apply -auto-approve
```

Once the provisioning completes you will see something like this:

```bash
Apply complete! Resources: 81 added, 0 changed, 0 destroyed.

Outputs:

aws_auth_configmap_yaml = <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::177043759486:role/scottford-dev-container-escape-demo-cc3c-iam-role
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes

EOT
cluster_arn = "arn:aws:eks:us-east-2:177043759486:cluster/scottford-dev-container-escape-demo-cc3c-cluster"
cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1EUXhOVEF5TWpJeU9Gb1hEVE15TURReE1qQXlNakl5T0Zvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBUExiCnd0L3VFV242YW8wdHN5NDJFblAvUHhJNUdmWlc0Y1gyVEh3WWV0YzJ1RXJ2UjdySUZIRU5zVXZTVTVQRFphM2cKVHcza3pIK2VDV0ZWSllxa0s4c3pMV3NxVTUxSHpiejRyU1NHN3BFdGdHclZlbi9JZHhpelFTTEoyeVIxYlA0OQp1TC9uVU40MGRVK0ErZi8zdG5xQ3E3UnNGenljcVBEYmtla0VKMTNyNEFseG9PTThURHRqWlBTdlZpdE8vUGpyClJhR1JmaG5veXpMR1BGSEpJc2NwK2M3UFZIc2luL0dwM2wyNHFNczgyU1ZjT2h6TENhTjM5ZFZLbTZuUnFYeEEKUE5UZTdkNFFBNi9WRFh0YWIvMUVMTmlpcngvVHhLZFZTRW02bVlxMi9Cd1NySVdRQUV0bnFkditHd2YxZ1RCWgpYbmdFRE9yMi83TkN5WGcvRWxFQ0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZKa3ZwcmJuckVYanU5b2tINk9MN2xQZzU0eVVNQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFCNCtSUDVlZnJoVGZveXZWVTFqc2c2YU9lb2g5d3FpanlUczlNN3FJT0NJemNaNUorSgp5U3YzVnpCRHgyS01iR1hZT2QyMWY4STlUQVNycG42Z0IxVFdJTWFadWVCQThQcjlmVTRWRHA3UnN2dmxLVkZXCkkzdncvN2U4REhLZzN4dEk1OUM0aW4vOGRkSWkvSTdQRWZyVGNveDZMZUNmTjZlOU4yNllpZ0QrYmtaeW9IbXcKSlo1VVlmNGFIRlM3STJoWkMyWU1TUUpwZjN6L1B2b1lZOHFBTy9kMEN5eW8wQU5pQUVERHhyRHZuOU81L2RmQgphNDIxcklNNmYxek1yM1NpU1dwajJkZ1pST2xnTmduS05LaWNyUThSZDdpaHVlWnhXMkVRZlROdGplT3RwNE1ZCjZQU2VyUGFyS0txa0NJVERmdC9WV2gra2tHYTRsUnBtUnVDYQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
cluster_endpoint = "https://FCE158C9CB11823E921FE9C902A1BA67.gr7.us-east-2.eks.amazonaws.com"
cluster_iam_role_arn = "arn:aws:iam::177043759486:role/eks-container-escape-cc3c"
cluster_iam_role_name = "eks-container-escape-cc3c"
cluster_iam_role_unique_id = "AROASSOFBMF7MTG4R7MGU"
cluster_id = "scottford-dev-container-escape-demo-cc3c-cluster"
cluster_name = "scottford-dev-container-escape-demo-cc3c-cluster"
cluster_platform_version = "eks.6"
cluster_primary_security_group_id = "sg-0eda416bd6bfc5e50"
cluster_security_group_arn = "arn:aws:ec2:us-east-2:177043759486:security-group/sg-0d904bb4507c70571"
cluster_security_group_id = "sg-0d904bb4507c70571"
cluster_status = "ACTIVE"
kali_linux_public_ip = "3.17.157.155"
node_security_group_arn = "arn:aws:ec2:us-east-2:177043759486:security-group/sg-06df9685ecab6b2a0"
node_security_group_id = "sg-06df9685ecab6b2a0"
region = "us-east-2"
```

## Connect to the cluster

After Terraform finishes provisioning, your local Kubeconfig is automatically updated to connect to your EKS cluster:

```bash
kubectl get nodes
NAME                                       STATUS   ROLES    AGE     VERSION
ip-10-0-5-7.us-east-2.compute.internal     Ready    <none>   6m14s   v1.21.5-eks-9017834
ip-10-0-6-242.us-east-2.compute.internal   Ready    <none>   6m6s    v1.21.5-eks-9017834
```

```bash
kubectl get deployments
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
dvwa-container-escape   1/1     1            1           9m55s
```

```bash
kubectl describe pods

Name:         dvwa-container-escape-85c776c9bd-7cf4h
Namespace:    default
Priority:     0
Node:         ip-10-0-5-7.us-east-2.compute.internal/10.0.5.7
Start Time:   Thu, 14 Apr 2022 19:29:06 -0700
Labels:       app=dvwa-container-escape
              pod-template-hash=85c776c9bd
Annotations:  kubernetes.io/psp: eks.privileged
Status:       Running
IP:           10.0.5.54
IPs:
  IP:           10.0.5.54
Controlled By:  ReplicaSet/dvwa-container-escape-85c776c9bd
Containers:
  dvwa:
    Container ID:   docker://d814f51104523b200d6c46dbb4c45d5fcc046adf26108f69a1fb48d0d0f9b573
    Image:          public.ecr.aws/x6s5a8t7/dvwa:latest
    Image ID:       docker-pullable://public.ecr.aws/x6s5a8t7/dvwa@sha256:8791eab52f1481d10e06bcd8a40188456ea3e5e4760e2f1407563c1e62e251f3
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Thu, 14 Apr 2022 19:29:31 -0700
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-cjv6n (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-cjv6n:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  8m25s (x4 over 10m)  default-scheduler  no nodes available to schedule pods
  Warning  FailedScheduling  8m17s                default-scheduler  0/1 nodes are available: 1 node(s) had taint {node.kubernetes.io/not-ready: }, that the pod didn't tolerate.
  Warning  FailedScheduling  8m7s                 default-scheduler  0/2 nodes are available: 2 node(s) had taint {node.kubernetes.io/not-ready: }, that the pod didn't tolerate.
  Normal   Scheduled         7m57s                default-scheduler  Successfully assigned default/dvwa-container-escape-85c776c9bd-7cf4h to ip-10-0-5-7.us-east-2.compute.internal
  Normal   Pulling           7m56s                kubelet            Pulling image "public.ecr.aws/x6s5a8t7/dvwa:latest"
  Normal   Pulled            7m34s                kubelet            Successfully pulled image "public.ecr.aws/x6s5a8t7/dvwa:latest" in 22.32723533s
  Normal   Created           7m32s                kubelet            Created container dvwa
  Normal   Started           7m32s                kubelet            Started container dvwa
```

## Kali Linux

A Kali Linux EC2 instance is provisioned into the VPC for the hacking demo. Terraform will output the PublicIP address of the instance so you can SSH in.

```bash
kali_linux_public_ip = "3.133.152.115"
```

Use your AWS EC2 SSH key for access:

```bash
ssh -i ~/.ssh/aws_rsa kali@3.133.152.115
The authenticity of host '3.133.152.115 (3.133.152.115)' can't be established.
ED25519 key fingerprint is SHA256:e6U/A+r+nvGI3g3TD8ElB2uSmIvtXyx3wFoR9L1luBw.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '3.133.152.115' (ED25519) to the list of known hosts.
Linux kali 5.15.0-kali3-cloud-amd64 #1 SMP Debian 5.15.15-2kali1 (2022-01-31) x86_64

The programs included with the Kali GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Kali GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
┏━(Message from Kali developers)
┃
┃ This is a cloud installation of Kali Linux. Learn more about
┃ the specificities of the various cloud images:
┃ ⇒ https://www.kali.org/docs/troubleshooting/common-cloud-setup/
┃
┗━(Run: “touch ~/.hushlogin” to hide this message)
┌──(kali㉿kali)-[~]
└─$ 
```







