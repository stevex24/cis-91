
variable "credentials_file" {
  default = "../secrets/cis-91.key"
}

variable "project" {
  default = "cis-91-terraform-326400"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  region      = var.region
  zone        = var.zone
  project     = var.project
}


resource "google_compute_network" "vpc_network" {
  name = "cis91-network"
}

resource "google_service_account" "proj1-service-account" {
  account_id   = "proj1-service-account"
  display_name = "proj1-service-account"
  description  = "Service account for project1"
}

resource "google_project_iam_member" "project_member" {
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.proj1-service-account.email}"
}

resource "google_compute_disk" "system" {
  name = "system"
  type = "pd-ssd"
  zone = var.zone
}

resource "google_compute_disk" "data" {
  name = "data"
  type = "pd-ssd"
  zone = var.zone
}

resource "google_storage_bucket" "steves-dokuwiki" {
  name          = "steves_prime-564819669946735512444543556507"
}  
  
resource "google_compute_instance" "vm_instance" {
  name         = "cis91"
  machine_type = "e2-micro"

  service_account {
    email  = google_service_account.proj1-service-account.email
    scopes = ["cloud-platform"]
  }

  attached_disk {
    source      = google_compute_disk.data.name
    device_name = "data"
  }

  attached_disk {
    source      = google_compute_disk.system.name
    device_name = "system"
  }  

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}  

resource "google_compute_firewall" "default-firewall" {
  name    = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}