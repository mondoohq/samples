# Random String
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}


resource "time_sleep" "wait_120_seconds" {
  #depends_on = [null_resource.previous]

  create_duration = "120s"
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
  prefix        = "lunalectric-${random_string.suffix.result}"
  names         = ["node"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
    "${var.project_id}=>roles/monitoring.viewer",
    "${var.project_id}=>roles/iam.serviceAccountUser",
  ]
  generate_keys = false
}

resource "google_kms_key_ring" "pass" {
  name = "pass-keyring-${random_string.suffix.result}"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "key" {
  name = "pass-key-${random_string.suffix.result}"
  key_ring = google_kms_key_ring.pass.id
  rotation_period = "2592000s"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    google_kms_key_ring.pass,
  ]
}
resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = [
     "serviceAccount:lunalectric-${random_string.suffix.result}-node@${var.project_id}.iam.gserviceaccount.com",
     "serviceAccount:service-${var.project_number}@container-engine-robot.iam.gserviceaccount.com",
  ]
  depends_on = [
    module.service_accounts-roles,
  ]
}

####

## Test subnet
resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges-1" {
  name          = "lunalectric-subnet-01-${random_string.suffix.result}"
  ip_cidr_range = "10.10.10.0/24"
  region        = "us-central1"
  network       = google_compute_network.custom-test.id
  project = var.project_id
  secondary_ip_range {
    range_name    = "lunalectric-subnet-01-secondary-01-pods-${random_string.suffix.result}"
    ip_cidr_range = "192.168.64.0/24"
  }
  secondary_ip_range {
    range_name    = "lunalectric-subnet-01-secondary-01-services-${random_string.suffix.result}"
    ip_cidr_range = "192.168.65.0/24"
  }
}

## Test Subnet 2
resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges-2" {
  name          = "lunalectric-subnet-02-${random_string.suffix.result}"
  ip_cidr_range = "10.10.11.0/24"
  region        = "us-central1"
  network       = google_compute_network.custom-test.id
  project = var.project_id
}

resource "google_compute_network" "custom-test" {
  name                    = "lunalectric-gke-${random_string.suffix.result}"
  auto_create_subnetworks = false
  project = var.project_id
}

resource "google_compute_firewall" "default" {
  name    = "firewall-lunalectric-gke-${random_string.suffix.result}"
  network = "lunalectric-gke-${random_string.suffix.result}"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22","80","443", "4242", "4243", "8001"]
  }

  source_ranges = ["0.0.0.0/0",]
  source_tags = null
  source_service_accounts = null
  target_tags             = null
  target_service_accounts = null

  depends_on = [
    google_compute_network.custom-test,
  ]
}

####

# GKE Cluster -> create aks cluster
resource "google_container_cluster" "primary" {
  provider = google-beta
  node_version = var.gke_version
  release_channel {
    channel = "STABLE"
  }
  default_max_pods_per_node   = 220
  # create resource to set bin_authz API in gcloud
  enable_binary_authorization = false
  enable_intranode_visibility = true
  enable_kubernetes_alpha     = false
  enable_l4_ilb_subsetting    = false
  enable_legacy_abac          = true
  enable_shielded_nodes       = false
  enable_tpu                  = false
  location                    = var.region
  logging_service             = "logging.googleapis.com/kubernetes"
  min_master_version          = var.gke_version
  monitoring_service          = "monitoring.googleapis.com/kubernetes"
  name                        = "lunalectric-gke-cluster-${random_string.suffix.result}"
  network                     = "lunalectric-gke-${random_string.suffix.result}"
  #master_authorized_networks_config {
  #  #gcp_public_cidrs_access_enabled = true
  #}
  database_encryption {
    state = "ENCRYPTED"
    key_name = google_kms_crypto_key.key.id
  }
  #private_cluster_config {
  #  enable_private_endpoint = false
  #  enable_private_nodes = false
  #  master_ipv4_cidr_block = "192.168.133.32/28"
  #  master_global_access_config {
  #    enabled = true
  #  }
  #}
  project                     = var.project_id
  remove_default_node_pool    = false
  subnetwork                  = "projects/${var.project_id}/regions/${var.region}/subnetworks/lunalectric-subnet-01-${random_string.suffix.result}"
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
          enable_integrity_monitoring = false
          enable_secure_boot          = false
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
        issue_client_certificate = true
      }
    }

    network_policy {
      enabled = false
    }

      node_pool {
        initial_node_count          = 1
        #instance_group_urls         = (known after apply)
        #managed_instance_group_urls = (known after apply)
        max_pods_per_node           = 110
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
          enable_private_nodes = false
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
            enable_integrity_monitoring = false
            enable_secure_boot          = false
          }

          #workload_metadata_config {
          #  mode = "GKE_METADATA"
          #}
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

      #workload_identity_config {
      #  workload_pool = "${var.project_id}.svc.id.goog"
      #}
  depends_on = [
    google_compute_network.custom-test,
    module.service_accounts-roles,
    google_kms_crypto_key_iam_binding.crypto_key,
    time_sleep.wait_120_seconds,
    google_compute_instance.pass-n2d-res,
  ]
}


### Attacker VM, taken from Resource-based n2d instance to make CSEK possible in GKE
resource "google_compute_instance" "pass-n2d-res" {
  provider = google-beta
  name         = "lunalectric-attacker-vm-${random_string.suffix.result}"
  machine_type = "e2-medium"
  project = var.project_id
  zone = var.zone

  #scheduling {
  #  automatic_restart   = true
  #  on_host_maintenance = "TERMINATE"
  #}

  network_interface {
    subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/lunalectric-subnet-02-${random_string.suffix.result}"

    access_config {

    }

  }
  boot_disk {
    #disk_encryption_key_raw = var.csek
    initialize_params {
      image = "ubuntu-minimal-2210-kinetic-amd64-v20230126"

    }
  }


  service_account {
    email = module.service_accounts-roles.email
    scopes = ["cloud-platform"]
  }

#  metadata_startup_script = data.template_file.init.rendered
  metadata_startup_script = templatefile("${path.module}/templates/prepare-hacking-vm.tpl", {project = var.project_id, region = var.region, zone = var.zone, instance = "lunalectric-attacker-vm-${random_string.suffix.result}"})

  depends_on = [
    module.service_accounts-roles,
    google_compute_network.custom-test,
    #data.template_file.init,
  ]
}