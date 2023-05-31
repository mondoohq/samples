#output "file" {
#    value = data.template_file.init.rendered
#}

#output "attacker_vm_name" {
#    value =  google_compute_instance.pass-n2d-res.name
#}
#
#output "target_cluster_name" {
#    value = google_container_cluster.primary.name
#}
#
#output "summary" {
#    value = <<EOT
#
#Connect to attacker VM (in 3-4 separate terminals):
#gcloud compute ssh ${google_compute_instance.pass-n2d-res.name}
#
#Connect to your GKE cluster via gcloud:
#gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region us-central1
#
#
#kubectl apply -f ../assets/dvwa-deployment.yml
#kubectl port-forward $(kubectl get pods -o name) 8080:80
#
#EOT
#
#}