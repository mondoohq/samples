output "file" {
    value = data.template_file.init.rendered
}

output "attacker_vm_name" {
    value =  google_compute_instance.pass-n2d-res.name
}

output "summary" {
    value = <<EOT

Connect to attacker VM (in 3-4 separate terminals):
gcloud compute ssh ${google_compute_instance.pass-n2d-res.name}

export KUBECONFIG="$ {PWD}/aks-kubeconfig"
kubectl apply -f ../assets/dvwa-deployment.yml
kubectl port-forward $(kubectl get pods -o name) 8080:80

EOT

}