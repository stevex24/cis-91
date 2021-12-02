
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
  region  = var.region
  zone    = var.zone 
  project = var.project
}

resource "google_compute_network" "custom-network" {
  name                    = "custom-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges_1" {
  name          = "subnet-1"
  ip_cidr_range = "10.240.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.custom-network.id
  secondary_ip_range {
    range_name    = "seondary-range-1"
    ip_cidr_range = "192.168.10.0/24"
  }
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges-2" {
  name          = "subnet-2"
  ip_cidr_range = "192.168.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.custom-network.id
  secondary_ip_range {
    range_name    = "seondary-range-2"
    ip_cidr_range = "192.169.10.0/24"
  }
}

resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges-3" {
  name          = "subnet-3"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.custom-network.id
  secondary_ip_range {
    range_name    = "seondary-range-3"
    ip_cidr_range = "192.170.10.0/24"
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "cis91"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network       = google_compute_network.custom-network.id
    access_config {
    }
    subnetwork = google_compute_subnetwork.network-with-private-secondary-ip-ranges-3.name
  }
}

resource "google_compute_firewall" "default-firewall" {
  name = "default-firewall"
  network       = google_compute_network.custom-network.id
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
