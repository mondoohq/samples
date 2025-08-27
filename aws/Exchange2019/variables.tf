// VARIABLES

variable "region" {
  default     = "us-east-2"
  description = "AWS Region"
}

variable "demo_name" {
  description = "A name to be applied as a suffix to project resources"
  type        = string
}

variable "ssh_key" {
  description = "SSH key associated with instances"
}

variable "ssh_key_path" {
  default     = "$HOME/.ssh/id_rsa"
  description = "Path to SSH key used for Kali Linux instance"
}

variable "publicIP" {
  description = "Your home PublicIP to configure access to VMs(if needed)"
}

variable "admin_password" {
  default = "MondooSPM1!"
}
