"use client";

import { useState, useCallback } from "react";
import { Copy, Check, Download } from "lucide-react";

type HermesConfig = {
  terminalBackend: "docker" | "local";
  containerCpu: number;
  containerMemory: number;
  containerDisk: number;
  containerPersistent: boolean;
  agentMaxTurns: number;
  compressionEnabled: boolean;
  compressionThreshold: number;
  toolProgress: "all" | "final" | "none";
  webEnabled: boolean;
  webPort: number;
};

const DEFAULTS: HermesConfig = {
  terminalBackend: "docker",
  containerCpu: 1,
  containerMemory: 5120,
  containerDisk: 51200,
  containerPersistent: true,
  agentMaxTurns: 90,
  compressionEnabled: true,
  compressionThreshold: 0.5,
  toolProgress: "all",
  webEnabled: true,
  webPort: 9119,
};

function buildYaml(c: HermesConfig): string {
  return `# Hermes Agent configuration
# Managed by Hermes-Agent-Cloud

terminal:
  backend: ${c.terminalBackend}          # Sandboxed Docker execution (recommended)
  container_cpu: ${c.containerCpu}
  container_memory: ${c.containerMemory}   # ${Math.round(c.containerMemory / 1024)} GB RAM
  container_disk: ${c.containerDisk}    # ${Math.round(c.containerDisk / 1024)} GB disk
  container_persistent: ${c.containerPersistent}

agent:
  max_turns: ${c.agentMaxTurns}

compression:
  enabled: ${c.compressionEnabled}
  threshold: ${c.compressionThreshold.toFixed(2)}

display:
  tool_progress: ${c.toolProgress}

web:
  enabled: ${c.webEnabled}
  port: ${c.webPort}               # Web dashboard port
`;
}

function CopyButton({ text }: { text: string }) {
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
      className="flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium border transition-all"
      style={{
        borderColor: copied ? "rgba(16,185,129,0.4)" : "var(--border)",
        color: copied ? "#10b981" : "var(--text-muted)",
        background: copied ? "rgba(16,185,129,0.08)" : "transparent",
      }}
    >
      {copied ? <Check size={12} /> : <Copy size={12} />}
      {copied ? "Copied!" : "Copy YAML"}
    </button>
  );
}

function DownloadButton({ text }: { text: string }) {
  const handleDownload = useCallback(() => {
    const blob = new Blob([text], { type: "text/yaml;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "hermes.yaml";
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 0);
  }, [text]);

  return (
    <button
      onClick={handleDownload}
      className="flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium border transition-all"
      style={{
        borderColor: "var(--border)",
        color: "var(--text-muted)",
        background: "transparent",
      }}
    >
      <Download size={12} />
      Download
    </button>
  );
}

function LabeledField({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <div className="flex items-start justify-between gap-4 py-3 border-b" style={{ borderColor: "var(--border)" }}>
      <div className="min-w-0">
        <p className="text-sm font-medium text-white">{label}</p>
        {hint && <p className="text-xs mt-0.5" style={{ color: "var(--text-dim)" }}>{hint}</p>}
      </div>
      <div className="shrink-0">{children}</div>
    </div>
  );
}

function NumberInput({ value, min, max, step = 1, onChange }: { value: number; min: number; max: number; step?: number; onChange: (v: number) => void }) {
  return (
    <input
      type="number"
      value={value}
      min={min}
      max={max}
      step={step}
      onChange={(e) => onChange(Number(e.target.value))}
      className="w-28 rounded-md border px-3 py-1.5 text-sm text-right outline-none"
      style={{ background: "var(--code-bg)", borderColor: "var(--border)", color: "var(--amber)", fontFamily: "var(--font-mono)" }}
    />
  );
}

function Toggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      onClick={() => onChange(!checked)}
      className="w-9 h-5 rounded-full border flex items-center transition-all relative"
      style={{
        background: checked ? "rgba(245,158,11,0.3)" : "var(--bg-card)",
        borderColor: checked ? "var(--amber)" : "var(--border)",
      }}
    >
      <span
        className="absolute w-3.5 h-3.5 rounded-full transition-all"
        style={{
          background: checked ? "var(--amber)" : "var(--text-dim)",
          left: checked ? "calc(100% - 1.125rem)" : "0.125rem",
        }}
      />
    </button>
  );
}

function SelectInput<T extends string>({ value, options, onChange }: { value: T; options: { value: T; label: string }[]; onChange: (v: T) => void }) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value as T)}
      className="rounded-md border px-3 py-1.5 text-sm outline-none"
      style={{ background: "var(--code-bg)", borderColor: "var(--border)", color: "var(--amber)", fontFamily: "var(--font-mono)" }}
    >
      {options.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
    </select>
  );
}

export default function ConfigBuilderPage() {
  const [config, setConfig] = useState<HermesConfig>(DEFAULTS);

  const set = useCallback(<K extends keyof HermesConfig>(key: K, value: HermesConfig[K]) => {
    setConfig((prev) => ({ ...prev, [key]: value }));
  }, []);

  const yaml = buildYaml(config);

  return (
    <div className="p-8 max-w-4xl">
      {/* Header */}
      <div className="mb-8">
        <span className="badge badge-amber mb-3">Config</span>
        <h1 className="text-2xl font-bold mb-2">Config Builder</h1>
        <p className="text-sm" style={{ color: "var(--text-muted)" }}>
          Visually configure{" "}
          <code style={{ fontFamily: "var(--font-mono)", color: "var(--amber)" }}>hermes.yaml</code> and copy
          the result. After deployment, upload it to{" "}
          <code style={{ fontFamily: "var(--font-mono)", color: "var(--text-muted)" }}>~/.hermes/config.yaml</code> on your instance.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* ── Controls ───────────────────────────────────────────────────── */}
        <div>
          <div className="rounded-xl border p-5" style={{ background: "var(--bg-card)", borderColor: "var(--border)" }}>
            {/* Terminal section */}
            <p className="text-xs font-bold uppercase tracking-widest mb-1" style={{ color: "var(--amber)" }}>terminal</p>

            <LabeledField label="Backend" hint="docker (recommended) or local shell">
              <SelectInput
                value={config.terminalBackend}
                options={[{ value: "docker", label: "docker" }, { value: "local", label: "local" }]}
                onChange={(v) => set("terminalBackend", v)}
              />
            </LabeledField>

            <LabeledField label="CPU (cores)" hint="vCPU allocated to the container">
              <NumberInput value={config.containerCpu} min={1} max={16} onChange={(v) => set("containerCpu", v)} />
            </LabeledField>

            <LabeledField label="Memory (MB)" hint={`${Math.round(config.containerMemory / 1024)} GB`}>
              <NumberInput value={config.containerMemory} min={512} max={32768} step={512} onChange={(v) => set("containerMemory", v)} />
            </LabeledField>

            <LabeledField label="Disk (MB)" hint={`${Math.round(config.containerDisk / 1024)} GB`}>
              <NumberInput value={config.containerDisk} min={10240} max={204800} step={1024} onChange={(v) => set("containerDisk", v)} />
            </LabeledField>

            <LabeledField label="Persistent container" hint="Keep container state between agent runs">
              <Toggle checked={config.containerPersistent} onChange={(v) => set("containerPersistent", v)} />
            </LabeledField>

            {/* Agent section */}
            <p className="text-xs font-bold uppercase tracking-widest mt-5 mb-1" style={{ color: "var(--amber)" }}>agent</p>

            <LabeledField label="Max turns" hint="Maximum agent turns per session">
              <NumberInput value={config.agentMaxTurns} min={1} max={500} onChange={(v) => set("agentMaxTurns", v)} />
            </LabeledField>

            {/* Compression section */}
            <p className="text-xs font-bold uppercase tracking-widest mt-5 mb-1" style={{ color: "var(--amber)" }}>compression</p>

            <LabeledField label="Enabled" hint="Compress context when threshold is exceeded">
              <Toggle checked={config.compressionEnabled} onChange={(v) => set("compressionEnabled", v)} />
            </LabeledField>

            <LabeledField label="Threshold" hint="Context fill ratio that triggers compression (0–1)">
              <NumberInput value={config.compressionThreshold} min={0.1} max={1.0} step={0.05} onChange={(v) => set("compressionThreshold", Math.min(1, Math.max(0.1, v)))} />
            </LabeledField>

            {/* Display section */}
            <p className="text-xs font-bold uppercase tracking-widest mt-5 mb-1" style={{ color: "var(--amber)" }}>display</p>

            <LabeledField label="Tool progress" hint="Which tool outputs to show">
              <SelectInput
                value={config.toolProgress}
                options={[
                  { value: "all",   label: "all" },
                  { value: "final", label: "final" },
                  { value: "none",  label: "none" },
                ]}
                onChange={(v) => set("toolProgress", v)}
              />
            </LabeledField>

            {/* Web section */}
            <p className="text-xs font-bold uppercase tracking-widest mt-5 mb-1" style={{ color: "var(--amber)" }}>web</p>

            <LabeledField label="Web dashboard" hint="Expose the Hermes web UI">
              <Toggle checked={config.webEnabled} onChange={(v) => set("webEnabled", v)} />
            </LabeledField>

            <LabeledField label="Port" hint="Port the web UI listens on">
              <NumberInput value={config.webPort} min={1024} max={65535} onChange={(v) => set("webPort", v)} />
            </LabeledField>
          </div>

          {/* Reset */}
          <button
            onClick={() => setConfig(DEFAULTS)}
            className="mt-3 text-xs border rounded-md px-3 py-1.5 transition-colors"
            style={{ borderColor: "var(--border)", color: "var(--text-dim)" }}
          >
            Reset to defaults
          </button>
        </div>

        {/* ── YAML preview ───────────────────────────────────────────────── */}
        <div className="flex flex-col">
          <div className="flex items-center justify-between mb-2">
            <p className="text-sm font-medium text-white">hermes.yaml preview</p>
            <div className="flex items-center gap-2">
              <DownloadButton text={yaml} />
              <CopyButton text={yaml} />
            </div>
          </div>
          <div className="terminal flex-1">
            <div className="terminal-bar">
              <span className="terminal-dot" style={{ background: "#ff5f57" }} />
              <span className="terminal-dot" style={{ background: "#febc2e" }} />
              <span className="terminal-dot" style={{ background: "#28c840" }} />
              <span className="ml-2 text-xs" style={{ color: "var(--text-dim)" }}>hermes.yaml</span>
            </div>
            <div className="terminal-body">
              <pre
                className="text-xs leading-relaxed whitespace-pre-wrap"
                style={{ color: "#f8f8f8", fontFamily: "var(--font-mono)" }}
              >
                {yaml}
              </pre>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
