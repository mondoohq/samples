// VARIABLES

variable "region" {
  default     = "us-east-2"
  description = "AWS Region"
}

variable "demo_name" {
  description = "A name to be applied as a suffix to project resources"
  type        = string
}

variable "kubernetes_version" {
  default     = "1.21"
  description = "Kubernetes cluster version used with EKS"
}

variable "ssh_key" {
  description = "SSH key associated with Kali Linux instance"
}

variable "ssh_key_path" {
  default     = "$HOME/.ssh/id_rsa"
  description = "Path to SSH key used for Kali Linux instance"
}

variable "publicIP" {
  description = "Your home PublicIP to configure access to Kali Linux (if needed)"
}

#variable "mondoo_credentials" {
#  description = "Path to config.json file. Can also create a config.json file and place it in the Terraform directory and simply set this variable to the value of 'config.json.'"
#}