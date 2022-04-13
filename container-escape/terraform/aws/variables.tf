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

variable "publicIP" {
  description = "Your home PublicIP to configure access to Kali Linux (if needed)"
}