resource "google_storage_bucket" "hermes" {
  count = var.manage_storage_bucket ? 1 : 0

  name                        = var.storage_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.effective_labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.storage_lifecycle_age
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.required]
}

resource "google_bigquery_dataset" "hermes" {
  count = var.manage_bigquery_dataset ? 1 : 0

  dataset_id = var.bigquery_dataset_id
  location   = var.region
  labels     = local.effective_labels

  depends_on = [google_project_service.required]
}

resource "google_pubsub_topic" "hermes" {
  count = var.manage_pubsub_topic ? 1 : 0

  name = var.pubsub_topic_name

  depends_on = [google_project_service.required]
}

resource "google_artifact_registry_repository" "hermes" {
  count = var.manage_artifact_registry ? 1 : 0

  location      = var.region
  repository_id = var.artifact_registry_id
  description   = "Hermes Agent artifacts"
  format        = "DOCKER"
  labels        = local.effective_labels

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret" "hermes" {
  count = var.manage_secret_manager ? 1 : 0

  secret_id = var.secret_manager_secret_id
  labels    = local.effective_labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.required]
}

resource "google_kms_key_ring" "hermes" {
  count = var.manage_kms ? 1 : 0

  name     = var.kms_keyring_name
  location = var.region

  depends_on = [google_project_service.required]
}

resource "google_kms_crypto_key" "hermes" {
  count = var.manage_kms ? 1 : 0

  name            = var.kms_crypto_key_name
  key_ring        = google_kms_key_ring.hermes[0].id
  rotation_period = "7776000s"
  labels          = local.effective_labels

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_billing_budget" "hermes" {
  count = var.budget_amount > 0 && var.billing_account != "" ? 1 : 0

  billing_account = "billingAccounts/${var.billing_account}"
  display_name    = "Hermes Agent monthly budget"

  budget_filter {
    projects = ["projects/${data.google_project.current.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_amount)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.8
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  depends_on = [google_project_service.required]
}
