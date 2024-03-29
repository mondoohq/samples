variable "region" {
  description = "The region/location where to deploy"
  type = string
}

variable "zone" {
  description = "The zone where to deploy"
  type = string
}

variable "project_id" {
  type = string
}

variable "project_number" {
  type = string
}

variable "gke_version" {
  type = string
  default = "1.25.15-gke.1083000"
}
