"use client";
import { Sparkles, Package, MessageSquare, Monitor, Cpu, Code2, Shuffle, LayoutDashboard, Layers, PuzzleIcon, GitBranch, Workflow } from "lucide-react";

const NEW_FEATURES = [
  {
    icon: GitBranch,
    color: '#10b981',
    title: 'Multi-Cloud Redundancy',
    desc: 'Deploy to two clouds simultaneously with automatic failover. hermes-deploy deploy --redundant gcp keeps you online even if one region goes down.',
  },
  {
    icon: Workflow,
    color: '#6366f1',
    title: 'GitHub Actions Integration',
    desc: 'Generate a tailored CI/CD workflow with hermes-deploy ci-setup. Auto-deploy on PR, destroy on close, upgrade on merge to main.',
  },
  {
    icon: Layers,
    color: "#f59e0b",
    title: "GCP Capability Packs",
    desc: "13 opt-in packs — Secret Manager, Vertex AI, BigQuery, Cloud Run and more. Mix presets with extra packs in one flag.",
  },
  {
    icon: PuzzleIcon,
    color: "#a78bfa",
    title: "rekipedia VS Code Extension",
    desc: "Ask, Search, and Wiki sidebar — full rekipedia integration inside VS Code. Scan any workspace from the command palette.",
  },
  {
    icon: Package,
    color: "#38bdf8",
    title: "pip install hermes-agent",
    desc: "Now a first-class PyPI package — install in seconds, no manual setup.",
  },
  {
    icon: MessageSquare,
    color: "#10b981",
    title: "22 Messaging Platforms",
    desc: "LINE and SimpleX added. Slack, Discord, Telegram, WhatsApp, and 18 more.",
  },
  {
    icon: Monitor,
    color: "#34d399",
    title: "Windows Beta Support",
    desc: "Run Hermes Agent natively on Windows — no WSL required.",
  },
  {
    icon: Cpu,
    color: "#e879f9",
    title: "hermes proxy",
    desc: "OpenAI-compatible local proxy — drop-in for any app that speaks the OpenAI API.",
  },
  {
    icon: Code2,
    color: "#f97316",
    title: "LSP Semantic Diagnostics",
    desc: "Live language-server diagnostics injected on every file write.",
  },
  {
    icon: Shuffle,
    color: "#7dd3fc",
    title: "/handoff Command",
    desc: "Transfer a live session between models mid-conversation without losing context.",
  },
  {
    icon: LayoutDashboard,
    color: "#34d399",
    title: "hermes web Dashboard",
    desc: "Built-in FastAPI + React SPA — monitor agents, logs, and tasks in real time.",
  },
];

export default function WhatsNew() {
  return (
    <section id="whats-new" className="py-24 px-6" style={{ background: "var(--surface-dim, rgba(255,255,255,0.02))" }}>
      <div className="max-w-6xl mx-auto">
        {/* Heading */}
        <div className="text-center mb-14">
          <span className="badge badge-amber mb-4 inline-flex items-center gap-1.5">
            <Sparkles size={12} />
            What&apos;s New
          </span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            Hermes Agent{" "}
            <span className="gradient-text">v0.14.0</span>
          </h2>
          <p className="text-base max-w-xl mx-auto" style={{ color: "var(--text-muted)" }}>
            The biggest release yet — PyPI distribution, 22 messaging platforms, Windows beta,
            a local proxy, LSP diagnostics, live handoffs, and a built-in web dashboard.
          </p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {NEW_FEATURES.map((f) => {
            const Icon = f.icon;
            return (
              <div
                key={f.title}
                className="card transition-all duration-300"
                style={{ borderColor: "var(--border)" }}
                onMouseEnter={e => {
                  const el = e.currentTarget as HTMLElement;
                  el.style.borderColor = f.color;
                  el.style.boxShadow = `0 0 20px ${f.color}33`;
                }}
                onMouseLeave={e => {
                  const el = e.currentTarget as HTMLElement;
                  el.style.borderColor = "var(--border)";
                  el.style.boxShadow = "none";
                }}
              >
                <div
                  className="w-10 h-10 rounded-lg flex items-center justify-center mb-4"
                  style={{ background: `${f.color}18`, border: `2px solid ${f.color}44` }}
                >
                  <Icon size={18} style={{ color: f.color }} />
                </div>
                <h3 className="font-bold text-white text-sm mb-1 font-mono">{f.title}</h3>
                <p className="text-xs leading-relaxed" style={{ color: "var(--text-muted)" }}>{f.desc}</p>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
