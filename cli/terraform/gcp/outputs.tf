output "public_ip" {
  description = "Reserved public IP address of the Hermes instance"
  value       = google_compute_address.hermes.address
}

output "instance_id" {
  description = "Instance name"
  value       = google_compute_instance.hermes.name
}

output "service_account_email" {
  description = "Service account attached to the Hermes VM"
  value       = google_service_account.hermes.email
}

output "network_name" {
  description = "Custom VPC for the Hermes deployment"
  value       = google_compute_network.hermes.name
}

output "subnetwork_name" {
  description = "Dedicated subnet for the Hermes deployment"
  value       = google_compute_subnetwork.hermes.name
}

output "gateway_url" {
  description = "Hermes gateway URL"
  value       = "http://${google_compute_address.hermes.address}:8080"
}
