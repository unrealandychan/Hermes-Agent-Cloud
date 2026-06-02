terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_project" "current" {
  project_id = var.project_id
}

locals {
  effective_labels = merge(
    {
      managed_by = "hermes-agent-cloud"
      service    = "hermes-agent"
      preset     = var.gcp_preset
    },
    var.resource_labels,
  )

  instance_tags = [
    "hermes-agent",
    "hermes-gateway",
    "hermes-dashboard",
  ]
}

resource "google_compute_address" "hermes" {
  name    = "hermes-static-ip"
  region  = var.region
  project = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_compute_instance" "hermes" {
  name         = "hermes-instance"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = local.instance_tags
  labels       = local.effective_labels

  boot_disk {
    initialize_params {
      image  = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size   = 50
      type   = "pd-ssd"
      labels = local.effective_labels
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.hermes.self_link
    access_config {
      nat_ip = google_compute_address.hermes.address
    }
  }

  service_account {
    email  = google_service_account.hermes.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_project_service.required,
    google_project_iam_member.hermes,
  ]
}
