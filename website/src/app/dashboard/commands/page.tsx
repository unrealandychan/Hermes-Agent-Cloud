"use client";

import { useState } from "react";
import { Search, Cloud } from "lucide-react";
import { CLI_COMMANDS, CloudProvider } from "@/lib/cloud-config";

const CLOUD_COLORS: Record<CloudProvider, string> = {
  aws:   "#FF9900",
  gcp:   "#4285F4",
  azure: "#0078D4",
};

export default function CommandsPage() {
  const [query, setQuery] = useState("");

  const filtered = CLI_COMMANDS.filter(
    (c) =>
      c.name.includes(query.toLowerCase()) ||
      c.description.toLowerCase().includes(query.toLowerCase())
  );

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

      {/* Search */}
      <div
        className="flex items-center gap-3 rounded-lg border px-4 py-2.5 mb-8"
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

      {/* Command list */}
      <div className="space-y-4">
        {filtered.length === 0 && (
          <p className="text-sm" style={{ color: "var(--text-muted)" }}>
            No commands match &ldquo;{query}&rdquo;.
          </p>
        )}
        {filtered.map((cmd) => (
          <div
            key={cmd.name}
            className="rounded-xl border p-5"
            style={{ background: "var(--bg-card)", borderColor: "var(--border)" }}
          >
            {/* Name row */}
            <div className="flex items-center gap-3 mb-2">
              <code
                className="text-base font-bold"
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
