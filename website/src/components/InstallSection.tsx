"use client";
import { useState } from "react";
import { Copy, Check } from "lucide-react";

const INSTALL_CMD = `curl -sSL https://raw.githubusercontent.com/unrealandychan/Hermes-Easy-Deploy/main/cli/install.sh | bash`;

const CLONE_STEPS = [
  { label: "Clone the repository", cmd: "git clone https://github.com/unrealandychan/Hermes-Easy-Deploy.git" },
  { label: "Enter the CLI directory", cmd: "cd Hermes-Easy-Deploy/cli" },
  { label: "Run the installer", cmd: "bash install.sh" },
];

const COMMANDS = [
  { cmd: "hermes-deploy",                          desc: "Launch interactive wizard" },
  { cmd: "hermes-deploy deploy --cloud aws",       desc: "Deploy to AWS (flags mode)" },
  { cmd: "hermes-deploy status --cloud azure",     desc: "Show running instance info" },
  { cmd: "hermes-deploy ssh --cloud gcp",          desc: "SSH into the instance" },
  { cmd: "hermes-deploy logs --cloud aws",         desc: "Tail journalctl logs" },
  { cmd: "hermes-deploy secrets --cloud azure",    desc: "Rotate API keys on the instance" },
  { cmd: "hermes-deploy destroy --cloud aws",      desc: "Tear down infra completely" },
];

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);
  async function copy() {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  }
  return (
    <button
      onClick={copy}
      className="p-1.5 rounded transition-all duration-150"
      style={{ background: copied ? "#34d39922" : "#ffffff11", color: copied ? "#34d399" : "#9ca3af" }}
      aria-label="Copy"
    >
      {copied ? <Check size={13} /> : <Copy size={13} />}
    </button>
  );
}

type InstallMethod = "oneliner" | "clone";

export default function InstallSection() {
  const [method, setMethod] = useState<InstallMethod>("oneliner");

  return (
    <section id="install" className="py-24 px-6" style={{ background: "var(--surface)" }}>
      <div className="max-w-4xl mx-auto">
        {/* Heading */}
        <div className="text-center mb-12">
          <span className="badge badge-amber mb-4">Install</span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
            Get up and running.{" "}
            <span className="gradient-text">Any machine.</span>
          </h2>
          <p className="text-base max-w-lg mx-auto" style={{ color: "var(--text-muted)" }}>
            Installs gum, Terraform, jq, and Hermes Easy Deploy. Works on macOS and
            Debian/Ubuntu Linux.
          </p>
        </div>

        {/* Install method tabs */}
        <div className="flex gap-2 mb-6">
          {(["oneliner", "clone"] as InstallMethod[]).map(tab => (
            <button
              key={tab}
              onClick={() => setMethod(tab)}
              className="px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-150"
              style={{
                background: method === tab ? "#f59e0b" : "#ffffff11",
                color: method === tab ? "#000" : "var(--text-muted)",
                border: method === tab ? "none" : "1px solid var(--border)",
              }}
            >
              {tab === "oneliner" ? "⚡ One-liner (recommended)" : "🔧 Clone & Install"}
            </button>
          ))}
        </div>

        {/* One-liner install */}
        {method === "oneliner" && (
          <div className="terminal rounded-xl mb-8 shadow-2xl">
            <div className="terminal-bar">
              <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#ff5f57" }} />
              <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#f59e0b" }} />
              <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#28c840" }} />
              <span className="ml-auto text-xs" style={{ color: "var(--text-dim)" }}>your terminal</span>
            </div>
            <div className="terminal-body flex items-center justify-between gap-4">
              <code
                className="font-mono text-sm flex-1"
                style={{ color: "#f59e0b" }}
              >
                {INSTALL_CMD}
              </code>
              <CopyButton text={INSTALL_CMD} />
            </div>
          </div>
        )}

        {/* Clone & Install */}
        {method === "clone" && (
          <div className="terminal rounded-xl mb-8 shadow-2xl">
            <div className="terminal-bar">
              <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#ff5f57" }} />
              <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#f59e0b" }} />
              <span className="w-3 h-3 rounded-full inline-block" style={{ background: "#28c840" }} />
              <span className="ml-auto text-xs" style={{ color: "var(--text-dim)" }}>your terminal</span>
            </div>
            <div className="terminal-body flex flex-col gap-3">
              {CLONE_STEPS.map(({ label, cmd }) => (
                <div key={cmd}>
                  <p className="text-xs mb-1" style={{ color: "var(--text-dim)" }}># {label}</p>
                  <div className="flex items-center justify-between gap-4">
                    <code className="font-mono text-sm flex-1" style={{ color: "#f59e0b" }}>
                      {cmd}
                    </code>
                    <CopyButton text={cmd} />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Commands table */}
        <div className="rounded-xl border overflow-hidden" style={{ borderColor: "var(--border)" }}>
          <div className="px-5 py-3 border-b" style={{ borderColor: "var(--border)", background: "#f59e0b0a" }}>
            <p className="text-sm font-semibold text-white">Available Commands</p>
          </div>
          <div className="divide-y" style={{ borderColor: "var(--border)" }}>
            {COMMANDS.map(({ cmd, desc }) => (
              <div
                key={cmd}
                className="flex items-center justify-between gap-4 px-5 py-3 transition-colors"
                style={{ background: "var(--card-bg)" }}
                onMouseEnter={e => { (e.currentTarget as HTMLElement).style.background = "#f59e0b08"; }}
                onMouseLeave={e => { (e.currentTarget as HTMLElement).style.background = "var(--card-bg)"; }}
              >
                <code className="font-mono text-xs flex-1" style={{ color: "#f59e0b" }}>
                  {cmd}
                </code>
                <span className="text-xs" style={{ color: "var(--text-dim)" }}>{desc}</span>
                <CopyButton text={cmd} />
              </div>
            ))}
          </div>
        </div>

        {/* Prerequisites */}
        <div
          className="mt-8 p-5 rounded-xl border text-sm"
          style={{ borderColor: "var(--border)", background: "var(--card-bg)" }}
        >
          <p className="font-semibold text-white mb-2">Prerequisites</p>
          <ul className="space-y-1" style={{ color: "var(--text-muted)" }}>
            {[
              "Cloud CLI (aws / az / gcloud) with valid credentials",
              "Terraform ≥ 1.6 (installer will set this up)",
              "gum ≥ 0.14 (installer will set this up)",
              "At least one LLM API key (OpenRouter, OpenAI, Anthropic, or Gemini)",
            ].map(item => (
              <li key={item} className="flex items-start gap-2">
                <span style={{ color: "#f59e0b" }}>→</span>
                {item}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
