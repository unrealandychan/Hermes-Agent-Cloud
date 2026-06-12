import Link from "next/link";
import { Rocket, Terminal, Settings, ArrowRight } from "lucide-react";

const CARDS = [
  {
    href: "/dashboard/deploy",
    icon: Rocket,
    title: "Deploy Wizard",
    description: "Visual step-by-step wizard that builds your CLI deploy command for AWS, GCP, or Azure.",
    accent: "#f59e0b",
  },
  {
    href: "/dashboard/commands",
    icon: Terminal,
    title: "Command Reference",
    description: "Searchable reference for every hermes-agent-cloud command, flag, and example.",
    accent: "#8b5cf6",
  },
  {
    href: "/dashboard/config",
    icon: Settings,
    title: "Config Builder",
    description: "Build and export a ready-to-use hermes.yaml configuration file visually.",
    accent: "#06b6d4",
  },
];

export default function DashboardHome() {
  return (
    <div className="p-8 max-w-4xl">
      {/* Header */}
      <div className="mb-10">
        <span className="badge badge-amber mb-4">Dashboard</span>
        <h1 className="text-3xl font-bold mb-3">
          Hermes Agent Cloud
        </h1>
        <p className="text-base" style={{ color: "var(--text-muted)" }}>
          A web-based companion for the{" "}
          <code
            className="px-1.5 py-0.5 rounded text-sm"
            style={{ background: "var(--code-bg)", color: "var(--amber)", fontFamily: "var(--font-mono)" }}
          >
            hermes-agent-cloud
          </code>{" "}
          CLI. Build deploy commands, browse documentation, and generate config files — all in one place.
        </p>
      </div>

      {/* Quick-start cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 mb-12">
        {CARDS.map(({ href, icon: Icon, title, description, accent }) => (
          <Link
            key={href}
            href={href}
            className="card group flex flex-col gap-4 no-underline"
            style={{ textDecoration: "none" }}
          >
            <div
              className="w-10 h-10 rounded-lg flex items-center justify-center"
              style={{ background: `${accent}18`, border: `1px solid ${accent}30` }}
            >
              <Icon size={20} style={{ color: accent }} />
            </div>
            <div>
              <h2 className="text-base font-semibold mb-1 text-white">{title}</h2>
              <p className="text-sm leading-relaxed" style={{ color: "var(--text-muted)" }}>
                {description}
              </p>
            </div>
            <span
              className="mt-auto flex items-center gap-1 text-sm font-medium"
              style={{ color: accent }}
            >
              Open <ArrowRight size={14} />
            </span>
          </Link>
        ))}
      </div>

      {/* Install reminder */}
      <div
        className="rounded-xl p-5 border"
        style={{ background: "var(--bg-card-alt)", borderColor: "var(--border)" }}
      >
        <p className="text-sm font-semibold mb-3" style={{ color: "var(--text-muted)" }}>
          Install the CLI first
        </p>
        <div className="terminal">
          <div className="terminal-bar">
            <span className="terminal-dot" style={{ background: "#ff5f57" }} />
            <span className="terminal-dot" style={{ background: "#febc2e" }} />
            <span className="terminal-dot" style={{ background: "#28c840" }} />
          </div>
          <div className="terminal-body text-sm">
            <span style={{ color: "#6ee7b7" }}>$</span>{" "}
            <span style={{ color: "#f8f8f8" }}>
              curl -fsSL https://raw.githubusercontent.com/unrealandychan/Hermes-Agent-Cloud/main/cli/install.sh | bash
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
