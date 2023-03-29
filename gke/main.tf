# Random String
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}


provider "google-beta" {
  project = var.project_id
  region = var.region
}

## service account new via modules with rolebindings
### fail basic service account module
module "service_accounts-roles" {
  source        = "terraform-google-modules/service-accounts/google"
  version       = "~> 3.0"
  project_id    = var.project_id
  prefix        = "lunalectric-sa-${random_string.suffix.result}"
  names         = ["nodes-fail"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
    "${var.project_id}=>roles/monitoring.viewer",
    "${var.project_id}=>roles/iam.serviceAccountAdmin",
  ]
  generate_keys = false
}


# Network VPC -> # Create virtual network
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "6.0.1"
  # insert the 3 required variables here
  project_id   = var.project_id
  network_name = "lunalectric-gke-${random_string.suffix.result}"
  # Create subnet
  subnets = [
        {
            subnet_name           = "lunalectric-subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "us-central1"
        },
    ]
  secondary_ranges = {
        lunalectric-subnet-01 = [
            {
                range_name    = "lunalectric-subnet-01-secondary-01-pods"
                ip_cidr_range = "192.168.64.0/24"
            },
            {
                range_name    = "lunalectric-subnet-01-secondary-01-services"
                ip_cidr_range = "192.168.65.0/24"
            },
        ]

        subnet-02 = []
    }
  firewall_rules = [
    {
      name                    = "lunalectric-allow-ssh"
      description             = null
      direction               = "INGRESS"
      priority                = null
      ranges                  = ["0.0.0.0/0"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [{
        protocol = "tcp"
        ports    = ["22","80","443"]
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
  ]
} 

# Create public IPs

# Create Network Security Group and rule

# Create network interface

# Create storage account for boot diagnostics

# Create (and display) an SSH key

# Create virtual machine

# GKE Cluster -> create aks cluster
resource "google_container_cluster" "primary" {
  provider = google-beta
  node_version = "1.23.16-gke.1100"
  release_channel {
    channel = "STABLE"
  }
  default_max_pods_per_node   = 8
  # create resource to set bin_authz API in gcloud
  enable_binary_authorization = true
  enable_intranode_visibility = true
  enable_kubernetes_alpha     = false
  enable_l4_ilb_subsetting    = false
  enable_legacy_abac          = false
  enable_shielded_nodes       = true
  enable_tpu                  = false
  location                    = var.region
  logging_service             = "logging.googleapis.com/kubernetes"
  min_master_version          = "1.23.16-gke.1100"
  monitoring_service          = "monitoring.googleapis.com/kubernetes"
  name                        = "lunalectric-gke-cluster-${random_string.suffix.result}"
  network                     = "lunalectric-gke-${random_string.suffix.result}"
  master_authorized_networks_config {
    #gcp_public_cidrs_access_enabled = true
  }
  database_encryption {
    state = "ENCRYPTED"
    key_name = google_kms_crypto_key.key.id
  }
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes = true
    master_ipv4_cidr_block = "192.168.133.32/28"
    master_global_access_config {
      enabled = true
    }
  }
  project                     = var.project_id
  remove_default_node_pool    = false
  subnetwork                  = "projects/${var.project_id}/regions/${var.region}/subnetworks/lunalectric-subnet-01"
    addons_config {
      #cloudrun_config {
      #}

      config_connector_config {
        enabled = false
      }

      dns_cache_config {
        enabled = false
      }

      gce_persistent_disk_csi_driver_config {
        enabled = true
      }

      gcp_filestore_csi_driver_config {
        enabled = false
      }

      gke_backup_agent_config {
        enabled = false
      }

      horizontal_pod_autoscaling {
        disabled = false
      }

      http_load_balancing {
        disabled = false
      }

      istio_config {
        auth     = "AUTH_MUTUAL_TLS"
        disabled = true
      }

      kalm_config {
        enabled = false
      }

      network_policy_config {
      disabled = true
      }
    }

    cluster_autoscaling {
      autoscaling_profile = "BALANCED"
      enabled             = false

      auto_provisioning_defaults {

        management {
          auto_repair     = true
          auto_upgrade    = true
          #upgrade_options = (known after apply)
        }

        shielded_instance_config {
          enable_integrity_monitoring = true
          enable_secure_boot          = true
        }

      }
    }

    confidential_nodes {
      enabled = false
    }

    cost_management_config {
      enabled = false
    }

    ip_allocation_policy {
      #cluster_ipv4_cidr_block       = (known after apply)
      #cluster_secondary_range_name  = "lunalectric-subnet-01-secondary-01-pods"
      #services_ipv4_cidr_block      = (known after apply)
      #services_secondary_range_name = "lunalectric-subnet-01-secondary-01-services"
    }

    maintenance_policy {
      daily_maintenance_window {
        #duration   = (known after apply)
        start_time = "05:00"
      }
    }

    master_auth {
      #client_certificate     = (known after apply)
      #client_key             = (sensitive value)
      #cluster_ca_certificate = (known after apply)

      client_certificate_config {
        issue_client_certificate = false
      }
    }

    network_policy {
      enabled = false
    }

      node_pool {
        initial_node_count          = 1
        #instance_group_urls         = (known after apply)
        #managed_instance_group_urls = (known after apply)
        max_pods_per_node           = 8
        name                        = "lunalectric-pool"
        #name_prefix                 = (known after apply)
        #node_count                  = (known after apply)
        #node_locations              = (known after apply)
        #version                     = (known after apply)

        management {
          auto_repair  = true
          auto_upgrade = true
        }

        network_config {
          #create_pod_range     = (known after apply)
          enable_private_nodes = true
          #pod_ipv4_cidr_block  = (known after apply)
          #pod_range            = (known after apply)
        }

        node_config {
          #disk_size_gb      = (known after apply)
          #disk_type         = (known after apply)
          #guest_accelerator = (known after apply)
          image_type        = "COS_CONTAINERD"
          #labels            = (known after apply)
          #local_ssd_count   = (known after apply)
          logging_variant   = "DEFAULT"
          machine_type      = "e2-medium"
          #metadata          = (known after apply)
          #min_cpu_platform  = (known after apply)
          #oauth_scopes      = (known after apply)
          preemptible       = false
          service_account   = module.service_accounts-roles.email
          spot              = false
          tags              = [
            "gke-lunalectric-gke-cluster-${random_string.suffix.result}",
            "gke-lunalectric-gke-cluster-${random_string.suffix.result}-default-pool",
          ]
          #taint             = (known after apply)

          shielded_instance_config {
            enable_integrity_monitoring = true
            enable_secure_boot          = true
          }

          workload_metadata_config {
            mode = "GKE_METADATA"
          }
        }
      }

      notification_config {
        pubsub {
          enabled = false
        }
      }

      timeouts {
        create = "45m"
        delete = "45m"
        update = "45m"
      }

      vertical_pod_autoscaling {
        enabled = false
      }

      workload_identity_config {
        workload_pool = "${var.project_id}.svc.id.goog"
      }
  depends_on = [
    module.network,
    module.service_accounts-roles,
    time_sleep.wait_120_seconds,
    google_kms_crypto_key_iam_binding.crypto_key,
  ]
}