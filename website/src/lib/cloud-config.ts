// cloud-config.ts — TypeScript constants derived from cli/lib/enums.sh and cli/lib/gcp_catalog.sh
// This is the single source of truth for cloud provider data used by the dashboard.

export type CloudProvider = "aws" | "gcp" | "azure";

// ── AWS ──────────────────────────────────────────────────────────────────────

export const AWS_REGIONS: { value: string; label: string }[] = [
  { value: "ap-east-1",      label: "ap-east-1      (Hong Kong)" },
  { value: "us-east-1",      label: "us-east-1      (N. Virginia)" },
  { value: "us-west-2",      label: "us-west-2      (Oregon)" },
  { value: "eu-west-1",      label: "eu-west-1      (Ireland)" },
  { value: "eu-central-1",   label: "eu-central-1   (Frankfurt)" },
  { value: "ap-southeast-1", label: "ap-southeast-1 (Singapore)" },
  { value: "ap-northeast-1", label: "ap-northeast-1 (Tokyo)" },
  { value: "ap-south-1",     label: "ap-south-1     (Mumbai)" },
];

export const AWS_INSTANCE_TYPES: { value: string; label: string; cost: string }[] = [
  { value: "t3.medium",  label: "t3.medium   — 2 vCPU  4 GB",  cost: "~$30/mo (On-Demand)  |  ~$9/mo (Spot)" },
  { value: "t3.large",   label: "t3.large    — 2 vCPU  8 GB",  cost: "~$60/mo (On-Demand)  |  ~$18/mo (Spot)" },
  { value: "t3.xlarge",  label: "t3.xlarge   — 4 vCPU  16 GB", cost: "~$120/mo (On-Demand)  |  ~$36/mo (Spot)" },
  { value: "t3.2xlarge", label: "t3.2xlarge  — 8 vCPU  32 GB", cost: "~$240/mo (On-Demand)  |  ~$72/mo (Spot)" },
];

// ── Azure ─────────────────────────────────────────────────────────────────────

export const AZURE_LOCATIONS: { value: string; label: string }[] = [
  { value: "eastasia",      label: "eastasia       (East Asia — Hong Kong)" },
  { value: "eastus",        label: "eastus         (East US)" },
  { value: "westus2",       label: "westus2        (West US 2)" },
  { value: "westeurope",    label: "westeurope     (West Europe)" },
  { value: "northeurope",   label: "northeurope    (North Europe)" },
  { value: "southeastasia", label: "southeastasia  (Southeast Asia)" },
  { value: "japaneast",     label: "japaneast      (Japan East)" },
];

export const AZURE_VM_SIZES: { value: string; label: string; cost: string }[] = [
  { value: "Standard_B2s",    label: "Standard_B2s     — 2 vCPU  4 GB",  cost: "~$35/mo (Pay-as-you-go)  |  ~$14/mo (1-yr reserved)" },
  { value: "Standard_D2s_v3", label: "Standard_D2s_v3  — 2 vCPU  8 GB",  cost: "~$70/mo (Pay-as-you-go)  |  ~$28/mo (1-yr reserved)" },
  { value: "Standard_D4s_v3", label: "Standard_D4s_v3  — 4 vCPU  16 GB", cost: "~$140/mo (Pay-as-you-go)  |  ~$56/mo (1-yr reserved)" },
  { value: "Standard_D8s_v3", label: "Standard_D8s_v3  — 8 vCPU  32 GB", cost: "~$280/mo (Pay-as-you-go)  |  ~$112/mo (1-yr reserved)" },
];

// ── GCP ───────────────────────────────────────────────────────────────────────

export const GCP_REGIONS: { value: string; label: string }[] = [
  { value: "asia-east2",      label: "asia-east2         (Hong Kong)" },
  { value: "us-central1",     label: "us-central1        (Iowa)" },
  { value: "us-east1",        label: "us-east1           (South Carolina)" },
  { value: "europe-west1",    label: "europe-west1       (Belgium)" },
  { value: "europe-west4",    label: "europe-west4       (Netherlands)" },
  { value: "asia-southeast1", label: "asia-southeast1    (Singapore)" },
  { value: "asia-northeast1", label: "asia-northeast1    (Tokyo)" },
];

export const GCP_MACHINE_TYPES: { value: string; label: string; cost: string }[] = [
  { value: "e2-medium",     label: "e2-medium      — 2 vCPU  4 GB",  cost: "~$25/mo (On-Demand)  |  ~$17/mo (Spot)" },
  { value: "e2-standard-2", label: "e2-standard-2  — 2 vCPU  8 GB",  cost: "~$49/mo (On-Demand)  |  ~$15/mo (Spot)" },
  { value: "e2-standard-4", label: "e2-standard-4  — 4 vCPU  16 GB", cost: "~$97/mo (On-Demand)  |  ~$29/mo (Spot)" },
  { value: "e2-standard-8", label: "e2-standard-8  — 8 vCPU  32 GB", cost: "~$194/mo (On-Demand)  |  ~$58/mo (Spot)" },
];

export type GcpPreset = "minimal" | "dev-agent" | "data-agent" | "ai-agent" | "full-ops";

export const GCP_PRESETS: {
  value: GcpPreset;
  label: string;
  packs: string[];
  costClass: string;
  blastRadius: string;
}[] = [
  {
    value: "minimal",
    label: "Minimal",
    packs: [],
    costClass: "Low",
    blastRadius: "Single VM, network, and IAM baseline only.",
  },
  {
    value: "dev-agent",
    label: "Dev Agent",
    packs: ["secretmanager", "storage", "artifactregistry", "logging", "monitoring"],
    costClass: "Medium",
    blastRadius: "VM plus build/runtime services with moderate project-level IAM scope.",
  },
  {
    value: "data-agent",
    label: "Data Agent",
    packs: ["storage", "bigquery", "pubsub", "scheduler"],
    costClass: "Medium-High",
    blastRadius: "VM plus storage, analytics, and messaging services.",
  },
  {
    value: "ai-agent",
    label: "AI Agent",
    packs: ["secretmanager", "storage", "artifactregistry", "vertexai", "logging", "monitoring"],
    costClass: "Medium-High",
    blastRadius: "VM plus AI, storage, and registry services.",
  },
  {
    value: "full-ops",
    label: "Full Ops",
    packs: [
      "secretmanager", "kms", "storage", "bigquery", "pubsub", "scheduler",
      "cloudrun", "artifactregistry", "logging", "monitoring", "alerts", "vertexai", "cloudsql",
    ],
    costClass: "High",
    blastRadius: "Broadest API surface and managed resources across security, data, and runtime packs.",
  },
];

export type GcpPack = {
  value: string;
  label: string;
  supportLevel: "supported" | "preview";
  description: string;
  api: string;
  role: string;
  managedResource: string;
};

export const GCP_CAPABILITY_PACKS: GcpPack[] = [
  { value: "secretmanager",  label: "Secret Manager",      supportLevel: "supported", description: "Managed secret containers only; secret values stay out of Terraform state.", api: "secretmanager.googleapis.com", role: "roles/secretmanager.admin", managedResource: "Secret Manager secret" },
  { value: "kms",            label: "Cloud KMS",           supportLevel: "supported", description: "Dedicated key ring and crypto key for future app-level encryption workflows.", api: "cloudkms.googleapis.com", role: "roles/cloudkms.admin", managedResource: "KMS key ring + crypto key" },
  { value: "storage",        label: "Cloud Storage",       supportLevel: "supported", description: "Managed bucket with versioning and lifecycle retention.", api: "storage.googleapis.com", role: "roles/storage.objectAdmin", managedResource: "Cloud Storage bucket" },
  { value: "bigquery",       label: "BigQuery",            supportLevel: "supported", description: "Managed analytics dataset for structured logs and billing exports.", api: "bigquery.googleapis.com", role: "roles/bigquery.dataEditor,roles/bigquery.jobUser", managedResource: "BigQuery dataset" },
  { value: "pubsub",         label: "Pub/Sub",             supportLevel: "supported", description: "Managed topic for events and automation.", api: "pubsub.googleapis.com", role: "roles/pubsub.editor", managedResource: "Pub/Sub topic" },
  { value: "scheduler",      label: "Cloud Scheduler",     supportLevel: "preview",   description: "API and IAM baseline for scheduled workflows.", api: "cloudscheduler.googleapis.com", role: "roles/cloudscheduler.admin", managedResource: "No managed resource yet (API + IAM only)" },
  { value: "cloudrun",       label: "Cloud Run",           supportLevel: "preview",   description: "API and IAM baseline for serverless app deployments.", api: "run.googleapis.com", role: "roles/run.developer", managedResource: "No managed resource yet (API + IAM only)" },
  { value: "artifactregistry", label: "Artifact Registry", supportLevel: "supported", description: "Managed Docker repository for build/runtime artifacts.", api: "artifactregistry.googleapis.com", role: "roles/artifactregistry.writer", managedResource: "Artifact Registry repository" },
  { value: "logging",        label: "Cloud Logging",       supportLevel: "preview",   description: "API and IAM baseline for log-heavy automation.", api: "logging.googleapis.com", role: "roles/logging.admin", managedResource: "No managed resource yet (API + IAM only)" },
  { value: "monitoring",     label: "Cloud Monitoring",    supportLevel: "preview",   description: "API and IAM baseline for metrics and dashboards.", api: "monitoring.googleapis.com", role: "roles/monitoring.editor", managedResource: "No managed resource yet (API + IAM only)" },
  { value: "alerts",         label: "Alerting",            supportLevel: "preview",   description: "API and IAM baseline for alert policies and governance.", api: "monitoring.googleapis.com", role: "roles/monitoring.alertPolicyEditor", managedResource: "No managed resource yet (API + IAM only)" },
  { value: "vertexai",       label: "Vertex AI",           supportLevel: "preview",   description: "API and IAM baseline for Gemini / Vertex AI workloads.", api: "aiplatform.googleapis.com", role: "roles/aiplatform.user", managedResource: "No managed resource yet (API + IAM only)" },
  { value: "cloudsql",       label: "Cloud SQL",           supportLevel: "preview",   description: "API and IAM baseline for managed relational data access.", api: "sqladmin.googleapis.com", role: "roles/cloudsql.admin", managedResource: "No managed resource yet (API + IAM only)" },
];

// ── API Key providers ─────────────────────────────────────────────────────────

export const API_PROVIDERS: { value: string; label: string; envVar: string }[] = [
  { value: "openrouter", label: "OpenRouter",        envVar: "OPENROUTER_API_KEY" },
  { value: "openai",     label: "OpenAI",            envVar: "OPENAI_API_KEY" },
  { value: "anthropic",  label: "Anthropic (Claude)", envVar: "ANTHROPIC_API_KEY" },
  { value: "gemini",     label: "Google Gemini",     envVar: "GEMINI_API_KEY" },
  { value: "novita",     label: "NovitaAI",          envVar: "NOVITA_API_KEY" },
  { value: "xai",        label: "xAI (SuperGrok)",   envVar: "XAI_API_KEY" },
];

// ── CLI commands reference ────────────────────────────────────────────────────

export type CliCommand = {
  name: string;
  description: string;
  flags?: string[];
  examples?: string[];
  cloud?: CloudProvider[];
};

export const CLI_COMMANDS: CliCommand[] = [
  {
    name: "deploy",
    description: "Deploy Hermes Agent to a cloud provider. Launches an interactive wizard if no flags are supplied.",
    flags: ["--cloud aws|gcp|azure", "--region REGION", "--preset PRESET (GCP)", "--packs pack1,pack2 (GCP)", "--config FILE", "--dry-run", "--explain"],
    examples: [
      "hermes-agent-cloud deploy --cloud aws",
      "hermes-agent-cloud deploy --cloud gcp --dry-run",
      "hermes-agent-cloud deploy --cloud gcp --preset ai-agent --packs pubsub",
      "hermes-agent-cloud deploy --cloud gcp --config ./gcp-profile.env --explain",
    ],
  },
  {
    name: "status",
    description: "Show live resource status for the deployed instance.",
    examples: ["hermes-agent-cloud status"],
  },
  {
    name: "open",
    description: "Open the Hermes WebUI in your browser via an SSH tunnel.",
    examples: ["hermes-agent-cloud open"],
  },
  {
    name: "tunnel",
    description: "Open an SSH tunnel to the WebUI (port-forward only, no browser launch).",
    examples: ["hermes-agent-cloud tunnel"],
  },
  {
    name: "ssh",
    description: "Open an interactive shell on the Hermes instance.",
    examples: ["hermes-agent-cloud ssh"],
  },
  {
    name: "logs",
    description: "Stream live Hermes gateway logs from the remote instance.",
    examples: ["hermes-agent-cloud logs"],
  },
  {
    name: "update",
    description: "Upgrade the Hermes Agent on the VM to the latest version.",
    examples: ["hermes-agent-cloud update"],
  },
  {
    name: "update-ip",
    description: "Re-detect your public IP and update cloud firewall rules.",
    examples: ["hermes-agent-cloud update-ip"],
  },
  {
    name: "secrets",
    description: "Rotate or update API keys stored in the cloud vault.",
    examples: ["hermes-agent-cloud secrets"],
  },
  {
    name: "billing",
    description: "Show cloud cost summary and budget alerts.",
    flags: ["--cloud aws|gcp|azure"],
    examples: [
      "hermes-agent-cloud billing",
      "hermes-agent-cloud billing --cloud aws",
    ],
  },
  {
    name: "ebs",
    description: "Manage the persistent EBS data volume (attach, detach, or migrate).",
    cloud: ["aws"],
    flags: ["status", "detach", "attach <instance-id>", "migrate"],
    examples: [
      "hermes-agent-cloud ebs status",
      "hermes-agent-cloud ebs detach",
      "hermes-agent-cloud ebs attach i-0abc123def456",
      "hermes-agent-cloud ebs migrate",
    ],
  },
  {
    name: "backup",
    description: "Snapshot skills, memory, and config to local and cloud storage.",
    examples: ["hermes-agent-cloud backup"],
  },
  {
    name: "doctor",
    description: "Run post-deploy diagnostics (service health, disk, memory, env). GCP support is richest.",
    examples: ["hermes-agent-cloud doctor"],
  },
  {
    name: "ci-setup",
    description: "Generate a GitHub Actions workflow for automated deploy pipelines.",
    examples: ["hermes-agent-cloud ci-setup"],
  },
  {
    name: "profile",
    description: "Manage named profiles for multi-instance deployments.",
    examples: ["hermes-agent-cloud profile"],
  },
  {
    name: "redundancy",
    description: "Manage multi-cloud failover: view status or trigger a failover.",
    flags: ["status", "failover"],
    examples: [
      "hermes-agent-cloud redundancy status",
      "hermes-agent-cloud redundancy failover",
    ],
  },
  {
    name: "destroy",
    description: "Tear down all deployed cloud resources for the current profile.",
    examples: ["hermes-agent-cloud destroy"],
  },
  {
    name: "version",
    description: "Print the current hermes-agent-cloud version.",
    examples: ["hermes-agent-cloud version"],
  },
];
