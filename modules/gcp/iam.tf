resource "google_service_account" "hermes" {
  account_id   = "hermes-agent"
  display_name = "Hermes Agent VM"
  project      = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "hermes" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.hermes.email}"

  depends_on = [google_project_service.required]
}
