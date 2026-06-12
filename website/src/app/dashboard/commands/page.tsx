"use client";

import { useState, useCallback } from "react";
import { Search, Cloud, Copy, Check } from "lucide-react";
import { CLI_COMMANDS, CloudProvider } from "@/lib/cloud-config";

const CLOUD_COLORS: Record<CloudProvider, string> = {
  aws:   "#FF9900",
  gcp:   "#4285F4",
  azure: "#0078D4",
};

const CLOUD_FILTERS: { value: CloudProvider | "all"; label: string }[] = [
  { value: "all",   label: "All" },
  { value: "aws",   label: "AWS" },
  { value: "gcp",   label: "GCP" },
  { value: "azure", label: "Azure" },
];

function CopyExampleButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = useCallback(() => {
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }, [text]);

  return (
    <button
      onClick={handleCopy}
      title="Copy first example"
      className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-xs font-medium border transition-all"
      style={{
        borderColor: copied ? "rgba(16,185,129,0.4)" : "var(--border)",
        color: copied ? "#10b981" : "var(--text-muted)",
        background: copied ? "rgba(16,185,129,0.08)" : "transparent",
      }}
    >
      {copied ? <Check size={11} /> : <Copy size={11} />}
      {copied ? "Copied!" : "Copy"}
    </button>
  );
}

export default function CommandsPage() {
  const [query, setQuery] = useState("");
  const [cloudFilter, setCloudFilter] = useState<CloudProvider | "all">("all");

  const filtered = CLI_COMMANDS.filter((c) => {
    const matchesSearch =
      c.name.includes(query.toLowerCase()) ||
      c.description.toLowerCase().includes(query.toLowerCase());
    const matchesCloud =
      cloudFilter === "all" ||
      !c.cloud ||
      c.cloud.includes(cloudFilter as CloudProvider);
    // commands with no cloud array are universal — show them for any filter
    const universalMatch = cloudFilter !== "all" && !c.cloud;
    return matchesSearch && (matchesCloud || universalMatch);
  });

  return (
    <div className="p-8 max-w-4xl">
      {/* Header */}
      <div className="mb-8">
        <span className="badge badge-amber mb-3">Commands</span>
        <h1 className="text-2xl font-bold mb-2">Command Reference</h1>
        <p className="text-sm" style={{ color: "var(--text-muted)" }}>
          All{" "}
          <code style={{ fontFamily: "var(--font-mono)", color: "var(--amber)" }}>
            hermes-agent-cloud
          </code>{" "}
          commands, flags, and examples.
        </p>
      </div>

      {/* Search + Cloud filter */}
      <div className="flex flex-col sm:flex-row gap-3 mb-8">
        <div
          className="flex items-center gap-3 rounded-lg border px-4 py-2.5 flex-1"
          style={{ background: "var(--bg-card)", borderColor: "var(--border)" }}
        >
          <Search size={15} style={{ color: "var(--text-dim)", flexShrink: 0 }} />
          <input
            type="text"
            placeholder="Search commands…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="flex-1 bg-transparent text-sm outline-none placeholder:text-[var(--text-dim)]"
            style={{ color: "var(--text)" }}
          />
        </div>
        <div className="flex items-center gap-1.5">
          {CLOUD_FILTERS.map(({ value, label }) => {
            const active = cloudFilter === value;
            const color = value !== "all" ? CLOUD_COLORS[value as CloudProvider] : undefined;
            return (
              <button
                key={value}
                onClick={() => setCloudFilter(value)}
                className="px-3 py-2 rounded-lg text-xs font-semibold border transition-all"
                style={{
                  background: active
                    ? color ? `${color}18` : "rgba(245,158,11,0.12)"
                    : "var(--bg-card)",
                  borderColor: active
                    ? color ? `${color}50` : "rgba(245,158,11,0.4)"
                    : "var(--border)",
                  color: active
                    ? color ?? "var(--amber)"
                    : "var(--text-muted)",
                }}
              >
                {label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Command list */}
      <div className="space-y-4">
        {filtered.length === 0 && (
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>
            No commands match your filters.
          </p>
        )}
        {filtered.map((cmd) => (
          <div
            key={cmd.name}
            className="rounded-xl border p-5"
            style={{ background: "var(--bg-card)", borderColor: "var(--border)" }}
          >
            {/* Name row */}
            <div className="flex items-center justify-between gap-3 mb-2">
              <div className="flex items-center gap-3 min-w-0">
                <code
                  className="text-base font-bold shrink-0"
                  style={{ color: "var(--amber)", fontFamily: "var(--font-mono)" }}
                >
                  {cmd.name}
                </code>
                {cmd.cloud && cmd.cloud.map((c) => (
                  <span
                    key={c}
                    className="badge text-xs"
                    style={{
                      fontSize: "0.65rem",
                      padding: "2px 7px",
                      background: `${CLOUD_COLORS[c]}14`,
                      borderColor: `${CLOUD_COLORS[c]}40`,
                      color: CLOUD_COLORS[c],
                    }}
                  >
                    <Cloud size={10} className="mr-1 inline-block" />
                    {c.toUpperCase()}
                  </span>
                ))}
              </div>
              {cmd.examples && cmd.examples.length > 0 && (
                <CopyExampleButton text={cmd.examples[0]} />
              )}
            </div>

            {/* Description */}
            <p className="text-sm mb-4" style={{ color: "var(--text-muted)" }}>
              {cmd.description}
            </p>

            {/* Flags */}
            {cmd.flags && cmd.flags.length > 0 && (
              <div className="mb-4">
                <p className="text-xs font-semibold uppercase tracking-widest mb-2" style={{ color: "var(--text-dim)" }}>
                  Flags / sub-commands
                </p>
                <div className="flex flex-wrap gap-2">
                  {cmd.flags.map((f) => (
                    <code
                      key={f}
                      className="text-xs px-2 py-1 rounded"
                      style={{ background: "var(--code-bg)", color: "var(--text-muted)", fontFamily: "var(--font-mono)", border: "1px solid var(--border)" }}
                    >
                      {f}
                    </code>
                  ))}
                </div>
              </div>
            )}

            {/* Examples */}
            {cmd.examples && cmd.examples.length > 0 && (
              <div>
                <p className="text-xs font-semibold uppercase tracking-widest mb-2" style={{ color: "var(--text-dim)" }}>
                  Examples
                </p>
                <div className="terminal">
                  <div className="terminal-bar">
                    <span className="terminal-dot" style={{ background: "#ff5f57" }} />
                    <span className="terminal-dot" style={{ background: "#febc2e" }} />
                    <span className="terminal-dot" style={{ background: "#28c840" }} />
                  </div>
                  <div className="terminal-body space-y-1">
                    {cmd.examples.map((ex) => (
                      <div key={ex}>
                        <span style={{ color: "#6ee7b7" }}>$</span>{" "}
                        <span style={{ color: "#f8f8f8" }}>{ex}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
