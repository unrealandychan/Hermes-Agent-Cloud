resource "google_compute_firewall" "hermes_ssh" {
  name    = "hermes-allow-ssh"
  network = google_compute_network.hermes.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["hermes-agent"]
  description   = "Allow SSH to Hermes instance from the configured CIDR only"

  depends_on = [google_project_service.required]
}

resource "google_compute_firewall" "hermes_gateway" {
  name    = "hermes-allow-gateway"
  network = google_compute_network.hermes.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["hermes-gateway"]
  description   = "Allow Hermes gateway from the configured CIDR only"

  depends_on = [google_project_service.required]
}

resource "google_compute_firewall" "hermes_dashboard" {
  name    = "hermes-allow-dashboard"
  network = google_compute_network.hermes.name

  allow {
    protocol = "tcp"
    ports    = ["9119"]
  }

  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["hermes-dashboard"]
  description   = "Allow Hermes dashboard from the configured CIDR only"

  depends_on = [google_project_service.required]
}
