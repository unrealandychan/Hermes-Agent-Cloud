import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { Sparkles, Rocket } from "lucide-react";

const RELEASES = [
  {
    version: 'v1.5.0',
    date: '2026-06-02',
    label: 'Multi-cloud redundancy + CI/CD + Helm + Terraform Registry',
    color: '#10b981',
    icon: Sparkles,
    badge: 'Latest',
    changes: [
      '`hermes-deploy deploy --redundant <cloud>` — deploy to 2 clouds simultaneously',
      '`hermes-deploy redundancy status|failover` — health check + one-command failover',
      '`hermes-deploy ci-setup` — generate GitHub Actions workflow (PR deploy/destroy, auto-upgrade, health checks)',
      '`hermes-deploy backup` — snapshot skills/memory/config to local + S3/GCS/Azure Blob',
      '`hermes-deploy billing alert` — set USD budget threshold with 80%/100% color-coded alerts',
      '`hermes-deploy secrets` — Bitwarden Secrets Manager integration',
      'Helm chart at `k8s/` — EKS/AKS/GKE support with liveness probes and PVC persistence',
      'Terraform Registry modules at `modules/aws|gcp|azure/` with auto-generated docs',
    ],
  },
  {
    version: "v1.4.0",
    date: "2026-06-02",
    label: "GCP Capability Packs + CI hardening",
    color: "#f59e0b",
    icon: Sparkles,
    badge: "",
    changes: [
      "13 opt-in GCP capability packs — Secret Manager, Vertex AI, BigQuery, Cloud Run, KMS, Artifact Registry, Pub/Sub, Scheduler, Cloud SQL, Storage, Logging, Monitoring, Alerts",
      "5 GCP deployment presets — minimal, dev-agent, data-agent, ai-agent, full-ops",
      "`gcp_catalog.sh` — central registry for all GCP APIs, IAM roles, and managed resources",
      "`hermes-deploy update-ip` — re-sync firewall CIDR rules when your local IP changes",
      "`hermes-deploy open` — open the gateway URL directly in your browser",
      "`hermes-deploy tunnel` — SSH tunnel to gateway (port 8080) without exposing it to the internet",
      "Self-update check on launch — CLI warns if a newer version is available on GitHub",
      "CI: `check-gcp-policy.sh` — automated IAM broad-role and open-firewall policy scan",
      "CI: `validate-gcp-catalog.sh` — regression tests for all preset and pack combinations",
    ],
  },
  {
    version: "v1.3.0",
    date: "2026-05-20",
    label: "EBS persistence + SSH hardening",
    color: "#38bdf8",
    icon: Sparkles,
    badge: null,
    changes: [
      "`hermes-deploy ebs status` / `migrate` — persistent EBS data volume management",
      "Dynamic IP recovery — `_get_live_ip()` auto-detects GCP VM IP after restart",
      "SSH keepalive config injected at deploy time — no more stale tunnel dropouts",
      "Post-deploy access guide printed after every successful deploy",
      "Preflight self-update check added to `preflight.sh`",
      "Azure Key Vault secret rotation via `hermes-deploy secrets`",
    ],
  },
  {
    version: "v1.2.0",
    date: "2026-05-14",
    label: "Multi-cloud billing + wizard overhaul",
    color: "#a78bfa",
    icon: Sparkles,
    badge: null,
    changes: [
      "`hermes-deploy billing` — unified cost summary, top services, and budget alerts across AWS, Azure, and GCP",
      "Interactive wizard redesign — cloud provider order now AWS → GCP → Azure",
      "IAM permission profiles — S3, Billing, RDS/SQL selectable from wizard",
      "GCP support parity with AWS and Azure — full wizard, deploy, ssh, logs, destroy",
      "gum-powered multi-select for IAM profile and region selection",
      "Masked API key input — secrets never echo to screen or shell history",
    ],
  },
  {
    version: "v1.1.0",
    date: "2026-05-26",
    label: "Hermes Agent v0.15.2 support",
    color: "#10b981",
    icon: Sparkles,
    badge: null,
    changes: [
      "`pip install hermes-agent` — now a PyPI package (v0.15.2)",
      "22 messaging platforms supported (LINE + SimpleX added)",
      "Windows beta support — no WSL needed",
      "`hermes proxy` — OpenAI-compatible local proxy",
      "LSP semantic diagnostics on every file write",
      "`/handoff` — live session transfer between models",
      "Built-in `hermes web` dashboard (FastAPI + React SPA)",
      "New LLM providers: NovitaAI and xAI SuperGrok",
    ],
  },
  {
    version: "v1.0.0",
    date: "2026-05-01",
    label: "Initial release",
    color: "#8b5cf6",
    icon: Rocket,
    badge: null,
    changes: [
      "One-command cloud deployment to AWS, GCP, and Azure",
      "Wizard-first CLI with guided setup",
      "IAM-native secret vaults for API key management",
      "Persistent EBS storage support",
      "Built-in billing insights dashboard",
      "One-command instance migration between clouds",
      "Terraform-powered infrastructure provisioning",
    ],
  },
];

export default function ChangelogPage() {
  return (
    <>
      <Navbar />
      <main className="min-h-screen pt-28 pb-24 px-6">
        <div className="max-w-3xl mx-auto">
          {/* Heading */}
          <div className="text-center mb-16">
            <span className="badge badge-amber mb-4 inline-block">Changelog</span>
            <h1 className="text-4xl sm:text-5xl font-extrabold text-white mb-4">
              Release{" "}
              <span className="gradient-text">History</span>
            </h1>
            <p className="text-base" style={{ color: "var(--text-muted)" }}>
              All notable changes to Hermes Agent Cloud.
            </p>
          </div>

          {/* Timeline */}
          <div className="relative">
            {/* Vertical line */}
            <div
              className="absolute left-5 top-0 bottom-0 w-px"
              style={{ background: "var(--border)" }}
            />

            <div className="space-y-12">
              {RELEASES.map((r) => {
                const Icon = r.icon;
                return (
                  <div key={r.version} className="relative pl-16">
                    {/* Icon dot */}
                    <div
                      className="absolute left-0 w-10 h-10 rounded-full flex items-center justify-center"
                      style={{ background: `${r.color}18`, border: `2px solid ${r.color}66` }}
                    >
                      <Icon size={18} style={{ color: r.color }} />
                    </div>

                    {/* Card */}
                    <div className="card" style={{ borderColor: `${r.color}44` }}>
                      <div className="flex items-center gap-3 mb-1 flex-wrap">
                        <span className="font-extrabold text-white text-lg font-mono">{r.version}</span>
                        {r.badge && (
                          <span
                            className="text-xs px-2 py-0.5 rounded-full font-semibold"
                            style={{ background: `${r.color}22`, color: r.color, border: `1px solid ${r.color}55` }}
                          >
                            {r.badge}
                          </span>
                        )}
                        <span className="text-xs font-mono ml-auto" style={{ color: "var(--text-dim)" }}>{r.date}</span>
                      </div>
                      <p className="text-sm font-semibold mb-4" style={{ color: r.color }}>{r.label}</p>

                      <ul className="space-y-2">
                        {r.changes.map((c) => (
                          <li key={c} className="flex items-start gap-2 text-sm" style={{ color: "var(--text-muted)" }}>
                            <span className="mt-1.5 w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ background: r.color }} />
                            <span>{c}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
