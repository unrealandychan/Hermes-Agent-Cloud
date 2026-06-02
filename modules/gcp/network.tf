resource "google_compute_network" "hermes" {
  name                    = "hermes-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "hermes" {
  name                     = "hermes-subnet"
  ip_cidr_range            = "10.20.0.0/24"
  region                   = var.region
  network                  = google_compute_network.hermes.id
  private_ip_google_access = true

  depends_on = [google_project_service.required]
}
