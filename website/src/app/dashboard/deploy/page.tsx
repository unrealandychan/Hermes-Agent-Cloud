"use client";

import { useState, useCallback } from "react";
import { Check, Copy, ChevronRight, ChevronLeft, Cloud, MapPin, Server, Package, Key, Terminal } from "lucide-react";
import {
  CloudProvider,
  AWS_REGIONS,
  AWS_INSTANCE_TYPES,
  AZURE_LOCATIONS,
  AZURE_VM_SIZES,
  GCP_REGIONS,
  GCP_MACHINE_TYPES,
  GCP_PRESETS,
  GCP_CAPABILITY_PACKS,
  API_PROVIDERS,
  GcpPreset,
} from "@/lib/cloud-config";

// ── Types ─────────────────────────────────────────────────────────────────────

type WizardState = {
  cloud: CloudProvider | "";
  region: string;
  instanceSize: string;
  gcpPreset: GcpPreset | "";
  gcpExtraPacks: string[];
  dryRun: boolean;
  configFile: string;
};

const INITIAL_STATE: WizardState = {
  cloud: "",
  region: "",
  instanceSize: "",
  gcpPreset: "",
  gcpExtraPacks: [],
  dryRun: false,
  configFile: "",
};

// ── Helpers ────────────────────────────────────────────────────────────────────

function buildCommand(state: WizardState): string {
  if (!state.cloud) return "hermes-agent-cloud deploy";
  const parts = ["hermes-agent-cloud deploy", `--cloud ${state.cloud}`];
  if (state.region) parts.push(`--region ${state.region}`);
  if (state.instanceSize) parts.push(`--size ${state.instanceSize}`);
  if (state.cloud === "gcp" && state.gcpPreset) parts.push(`--preset ${state.gcpPreset}`);
  if (state.cloud === "gcp" && state.gcpExtraPacks.length > 0)
    parts.push(`--packs ${state.gcpExtraPacks.join(",")}`);
  if (state.dryRun) parts.push("--dry-run");
  if (state.configFile) parts.push(`--config ${state.configFile}`);
  return parts.join(" ");
}

// ── Step definitions ───────────────────────────────────────────────────────────

const STEPS = [
  { id: "cloud",    label: "Cloud",    icon: Cloud },
  { id: "region",   label: "Region",   icon: MapPin },
  { id: "size",     label: "Size",     icon: Server },
  { id: "packs",    label: "Packs",    icon: Package },
  { id: "api",      label: "API Keys", icon: Key },
  { id: "review",   label: "Review",   icon: Terminal },
];

// ── Sub-components ────────────────────────────────────────────────────────────

function SelectCard({
  selected,
  onClick,
  children,
}: {
  selected: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className="text-left rounded-xl border p-4 transition-all cursor-pointer w-full"
      style={{
        background: selected ? "rgba(245,158,11,0.08)" : "var(--bg-card)",
        borderColor: selected ? "rgba(245,158,11,0.5)" : "var(--border)",
        outline: "none",
      }}
    >
      {children}
    </button>
  );
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
      {copied ? "Copied!" : "Copy"}
    </button>
  );
}

// ── Step renderers ─────────────────────────────────────────────────────────────

function StepCloud({ state, update }: { state: WizardState; update: (s: Partial<WizardState>) => void }) {
  const clouds: { value: CloudProvider; label: string; desc: string; badge: string }[] = [
    { value: "aws",   label: "AWS",   desc: "Amazon Web Services — broad ecosystem, spot instances", badge: "bg-[#FF9900]/10 text-[#FF9900] border-[#FF9900]/30" },
    { value: "gcp",   label: "GCP",   desc: "Google Cloud Platform — presets, capability packs, Vertex AI", badge: "bg-[#4285F4]/10 text-[#4285F4] border-[#4285F4]/30" },
    { value: "azure", label: "Azure", desc: "Microsoft Azure — enterprise-ready, Key Vault secrets", badge: "bg-[#0078D4]/10 text-[#0078D4] border-[#0078D4]/30" },
  ];

  return (
    <div className="space-y-3">
      {clouds.map((c) => (
        <SelectCard key={c.value} selected={state.cloud === c.value} onClick={() => update({ cloud: c.value, region: "", instanceSize: "", gcpPreset: "", gcpExtraPacks: [] })}>
          <div className="flex items-center gap-3">
            <span className={`badge border text-xs ${c.badge}`}>{c.label}</span>
            <span className="text-sm" style={{ color: "var(--text-muted)" }}>{c.desc}</span>
          </div>
        </SelectCard>
      ))}
    </div>
  );
}

function StepRegion({ state, update }: { state: WizardState; update: (s: Partial<WizardState>) => void }) {
  const regions =
    state.cloud === "aws"   ? AWS_REGIONS :
    state.cloud === "azure" ? AZURE_LOCATIONS :
    GCP_REGIONS;

  return (
    <div className="space-y-2">
      {regions.map((r) => (
        <SelectCard key={r.value} selected={state.region === r.value} onClick={() => update({ region: r.value })}>
          <span className="font-mono text-sm" style={{ color: state.region === r.value ? "var(--amber)" : "var(--text)" }}>
            {r.label}
          </span>
        </SelectCard>
      ))}
    </div>
  );
}

function StepSize({ state, update }: { state: WizardState; update: (s: Partial<WizardState>) => void }) {
  const sizes =
    state.cloud === "aws"   ? AWS_INSTANCE_TYPES :
    state.cloud === "azure" ? AZURE_VM_SIZES :
    GCP_MACHINE_TYPES;

  return (
    <div className="space-y-3">
      {sizes.map((s) => (
        <SelectCard key={s.value} selected={state.instanceSize === s.value} onClick={() => update({ instanceSize: s.value })}>
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="font-mono text-sm font-medium" style={{ color: state.instanceSize === s.value ? "var(--amber)" : "var(--text)" }}>
                {s.value}
              </p>
              <p className="text-xs mt-0.5" style={{ color: "var(--text-muted)" }}>{s.label.split("—")[1]?.trim()}</p>
            </div>
            <span className="text-xs shrink-0" style={{ color: "var(--text-dim)" }}>{s.cost}</span>
          </div>
        </SelectCard>
      ))}
    </div>
  );
}

function StepPacks({ state, update }: { state: WizardState; update: (s: Partial<WizardState>) => void }) {
  if (state.cloud !== "gcp") {
    return (
      <p className="text-sm" style={{ color: "var(--text-muted)" }}>
        Capability packs are a GCP-only feature. Continue to the next step.
      </p>
    );
  }

  const togglePack = (pack: string) => {
    const current = state.gcpExtraPacks;
    const presetPacks = state.gcpPreset
      ? (GCP_PRESETS.find(p => p.value === state.gcpPreset)?.packs ?? [])
      : [];
    if (presetPacks.includes(pack)) return; // preset-included packs can't be toggled off here
    const next = current.includes(pack) ? current.filter(p => p !== pack) : [...current, pack];
    update({ gcpExtraPacks: next });
  };

  const presetPacks = state.gcpPreset
    ? (GCP_PRESETS.find(p => p.value === state.gcpPreset)?.packs ?? [])
    : [];

  return (
    <div className="space-y-5">
      {/* Preset selector */}
      <div>
        <p className="text-sm font-medium mb-3 text-white">Choose a preset <span className="text-xs font-normal" style={{ color: "var(--text-muted)" }}>(optional)</span></p>
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
          {GCP_PRESETS.map((p) => (
            <SelectCard
              key={p.value}
              selected={state.gcpPreset === p.value}
              onClick={() => update({ gcpPreset: p.value, gcpExtraPacks: [] })}
            >
              <p className="text-sm font-medium" style={{ color: state.gcpPreset === p.value ? "var(--amber)" : "var(--text)" }}>{p.label}</p>
              <p className="text-xs mt-1" style={{ color: "var(--text-dim)" }}>Cost: {p.costClass}</p>
            </SelectCard>
          ))}
          <SelectCard selected={state.gcpPreset === ""} onClick={() => update({ gcpPreset: "", gcpExtraPacks: [] })}>
            <p className="text-sm font-medium" style={{ color: state.gcpPreset === "" ? "var(--amber)" : "var(--text)" }}>None</p>
            <p className="text-xs mt-1" style={{ color: "var(--text-dim)" }}>Custom packs only</p>
          </SelectCard>
        </div>
      </div>

      {/* Extra packs */}
      <div>
        <p className="text-sm font-medium mb-3 text-white">Add extra packs <span className="text-xs font-normal" style={{ color: "var(--text-muted)" }}>(optional)</span></p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
          {GCP_CAPABILITY_PACKS.map((pack) => {
            const fromPreset = presetPacks.includes(pack.value);
            const selected = fromPreset || state.gcpExtraPacks.includes(pack.value);
            return (
              <button
                key={pack.value}
                onClick={() => togglePack(pack.value)}
                disabled={fromPreset}
                className="text-left rounded-lg border p-3 transition-all"
                style={{
                  background: selected ? "rgba(245,158,11,0.06)" : "var(--bg-card)",
                  borderColor: selected ? "rgba(245,158,11,0.35)" : "var(--border)",
                  opacity: fromPreset ? 0.6 : 1,
                  cursor: fromPreset ? "default" : "pointer",
                }}
              >
                <div className="flex items-center justify-between gap-2">
                  <span className="text-sm font-medium" style={{ color: selected ? "var(--amber)" : "var(--text)" }}>
                    {pack.label}
                  </span>
                  <div className="flex items-center gap-1.5">
                    {fromPreset && (
                      <span className="badge text-xs" style={{ fontSize: "0.65rem", padding: "2px 6px" }}>preset</span>
                    )}
                    <span
                      className="badge text-xs"
                      style={{
                        fontSize: "0.65rem",
                        padding: "2px 6px",
                        background: pack.supportLevel === "supported" ? "rgba(16,185,129,0.1)" : "rgba(245,158,11,0.1)",
                        borderColor: pack.supportLevel === "supported" ? "rgba(16,185,129,0.3)" : "rgba(245,158,11,0.3)",
                        color: pack.supportLevel === "supported" ? "#10b981" : "var(--amber)",
                      }}
                    >
                      {pack.supportLevel}
                    </span>
                  </div>
                </div>
                <p className="text-xs mt-1" style={{ color: "var(--text-dim)" }}>{pack.description}</p>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function StepApi() {
  return (
    <div className="space-y-4">
      <p className="text-sm" style={{ color: "var(--text-muted)" }}>
        The deploy wizard will prompt you for API keys interactively. Keys are stored securely in your cloud vault —
        never in Terraform state. Set one or more of the following environment variables before running the CLI,
        or enter them at the prompt.
      </p>
      <div className="space-y-2">
        {API_PROVIDERS.map((p) => (
          <div
            key={p.value}
            className="rounded-lg border px-4 py-3 flex items-center justify-between"
            style={{ background: "var(--bg-card)", borderColor: "var(--border)" }}
          >
            <span className="text-sm font-medium text-white">{p.label}</span>
            <code
              className="text-xs px-2 py-1 rounded"
              style={{ background: "var(--code-bg)", color: "var(--amber)", fontFamily: "var(--font-mono)" }}
            >
              {p.envVar}
            </code>
          </div>
        ))}
      </div>
    </div>
  );
}

function StepReview({ state, update }: { state: WizardState; update: (s: Partial<WizardState>) => void }) {
  const command = buildCommand(state);

  const summaryRows = [
    { label: "Cloud",          value: state.cloud || "—" },
    { label: "Region",         value: state.region || "—" },
    { label: "Instance size",  value: state.instanceSize || "—" },
    ...(state.cloud === "gcp" ? [
      { label: "GCP preset",   value: state.gcpPreset || "none" },
      { label: "Extra packs",  value: state.gcpExtraPacks.length ? state.gcpExtraPacks.join(", ") : "none" },
    ] : []),
    { label: "Dry-run mode",   value: state.dryRun ? "yes" : "no" },
  ];

  return (
    <div className="space-y-6">
      {/* Summary table */}
      <div className="rounded-xl border divide-y divide-[rgba(255,255,255,0.07)]" style={{ borderColor: "var(--border)" }}>
        {summaryRows.map(({ label, value }) => (
          <div key={label} className="flex items-center justify-between px-4 py-2.5">
            <span className="text-sm" style={{ color: "var(--text-muted)" }}>{label}</span>
            <span className="text-sm font-medium font-mono" style={{ color: "var(--amber)" }}>{value}</span>
          </div>
        ))}
      </div>

      {/* Generated command */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <p className="text-sm font-medium text-white">Generated command</p>
          <CopyButton text={command} />
        </div>
        <div className="terminal">
          <div className="terminal-bar">
            <span className="terminal-dot" style={{ background: "#ff5f57" }} />
            <span className="terminal-dot" style={{ background: "#febc2e" }} />
            <span className="terminal-dot" style={{ background: "#28c840" }} />
          </div>
          <div className="terminal-body">
            <span style={{ color: "#6ee7b7" }}>$</span>{" "}
            <span style={{ color: "#f8f8f8" }}>{command}</span>
          </div>
        </div>
      </div>

      {/* Dry-run toggle */}
      <label
        className="flex items-center gap-3 cursor-pointer select-none"
        onClick={() => update({ dryRun: !state.dryRun })}
      >
        <input
          type="checkbox"
          checked={state.dryRun}
          onChange={() => update({ dryRun: !state.dryRun })}
          className="sr-only"
        />
        <div
          className="w-9 h-5 rounded-full border flex items-center transition-all relative"
          style={{
            background: state.dryRun ? "rgba(245,158,11,0.3)" : "var(--bg-card)",
            borderColor: state.dryRun ? "var(--amber)" : "var(--border)",
          }}
        >
          <span
            className="absolute w-3.5 h-3.5 rounded-full transition-all"
            style={{
              background: state.dryRun ? "var(--amber)" : "var(--text-dim)",
              left: state.dryRun ? "calc(100% - 1.125rem)" : "0.125rem",
            }}
          />
        </div>
        <span className="text-sm" style={{ color: "var(--text-muted)" }}>Add <code style={{ fontFamily: "var(--font-mono)", color: "var(--amber)" }}>--dry-run</code> flag (preview only, no resources created)</span>
      </label>
    </div>
  );
}

// ── Main wizard ───────────────────────────────────────────────────────────────

export default function DeployWizard() {
  const [step, setStep] = useState(0);
  const [state, setWizardState] = useState<WizardState>(INITIAL_STATE);

  const update = useCallback((partial: Partial<WizardState>) => {
    setWizardState((prev) => ({ ...prev, ...partial }));
  }, []);

  const canAdvance = () => {
    if (step === 0) return state.cloud !== "";
    if (step === 1) return state.region !== "";
    if (step === 2) return state.instanceSize !== "";
    return true;
  };

  const stepContent = [
    <StepCloud    key="cloud"  state={state} update={update} />,
    <StepRegion   key="region" state={state} update={update} />,
    <StepSize     key="size"   state={state} update={update} />,
    <StepPacks    key="packs"  state={state} update={update} />,
    <StepApi      key="api" />,
    <StepReview   key="review" state={state} update={update} />,
  ];

  return (
    <div className="p-8 max-w-3xl">
      {/* Header */}
      <div className="mb-8">
        <span className="badge badge-amber mb-3">Deploy Wizard</span>
        <h1 className="text-2xl font-bold mb-2">Build your deploy command</h1>
        <p className="text-sm" style={{ color: "var(--text-muted)" }}>
          Step through the options below to generate a ready-to-run{" "}
          <code style={{ fontFamily: "var(--font-mono)", color: "var(--amber)" }}>hermes-agent-cloud deploy</code> command.
        </p>
      </div>

      {/* Step progress bar */}
      <div className="flex items-center gap-1 mb-8">
        {STEPS.map((s, i) => {
          const Icon = s.icon;
          const done = i < step;
          const active = i === step;
          return (
            <div key={s.id} className="flex items-center gap-1">
              <button
                onClick={() => i <= step && setStep(i)}
                title={done ? `Go back to ${s.label}` : undefined}
                className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-md text-xs font-medium transition-all"
                style={{
                  background: active ? "rgba(245,158,11,0.12)" : done ? "rgba(16,185,129,0.08)" : "transparent",
                  color: active ? "var(--amber)" : done ? "#10b981" : "var(--text-dim)",
                  border: active ? "1px solid rgba(245,158,11,0.3)" : done ? "1px solid rgba(16,185,129,0.2)" : "1px solid transparent",
                  cursor: done ? "pointer" : i === step ? "default" : "not-allowed",
                }}
                disabled={i > step}
              >
                {done ? <Check size={12} /> : <Icon size={12} />}
                <span className="hidden sm:inline">{s.label}</span>
              </button>
              {i < STEPS.length - 1 && (
                <div
                  className="w-4 h-px"
                  style={{ background: done ? "#10b981" : "var(--border)" }}
                />
              )}
            </div>
          );
        })}
      </div>

      {/* Step content */}
      <div className="mb-8">
        <h2 className="text-base font-semibold mb-5 flex items-center gap-2 text-white">
          {(() => { const Icon = STEPS[step].icon; return <Icon size={16} style={{ color: "var(--amber)" }} />; })()}
          {STEPS[step].label}
        </h2>
        {stepContent[step]}
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between pt-4 border-t" style={{ borderColor: "var(--border)" }}>
        <button
          onClick={() => setStep((s) => Math.max(0, s - 1))}
          disabled={step === 0}
          className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border transition-all disabled:opacity-30 disabled:cursor-not-allowed"
          style={{ borderColor: "var(--border)", color: "var(--text-muted)" }}
        >
          <ChevronLeft size={15} />
          Back
        </button>

        {step < STEPS.length - 1 ? (
          <button
            onClick={() => setStep((s) => s + 1)}
            disabled={!canAdvance()}
            className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all disabled:opacity-40 disabled:cursor-not-allowed"
            style={{ background: "var(--amber)", color: "#000", fontWeight: 700 }}
          >
            Continue
            <ChevronRight size={15} />
          </button>
        ) : (
          <CopyButton text={buildCommand(state)} />
        )}
      </div>
    </div>
  );
}
