"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { Zap, Rocket, Terminal, Settings, BookOpen, LayoutDashboard, Menu, X, ChevronRight, Newspaper } from "lucide-react";

const NAV_ITEMS = [
  { href: "/dashboard",          label: "Overview",   icon: LayoutDashboard },
  { href: "/dashboard/deploy",   label: "Deploy",     icon: Rocket },
  { href: "/dashboard/commands", label: "Commands",   icon: Terminal },
  { href: "/dashboard/config",   label: "Config",     icon: Settings },
  { href: "/changelog",          label: "What's New", icon: Newspaper },
];

// Top-level routes that should not be treated as prefixes for active matching
const EXACT_MATCH_HREFS = new Set(["/dashboard", "/changelog"]);

function isNavItemActive(href: string, pathname: string): boolean {
  if (EXACT_MATCH_HREFS.has(href)) return pathname === href;
  return pathname.startsWith(href);
}

// Map href → human-readable breadcrumb label
const BREADCRUMB_LABELS: Record<string, string> = {
  "/dashboard":          "Overview",
  "/dashboard/deploy":   "Deploy Wizard",
  "/dashboard/commands": "Command Reference",
  "/dashboard/config":   "Config Builder",
  "/changelog":          "What's New",
};

function Breadcrumb({ pathname }: { pathname: string }) {
  if (pathname === "/dashboard") return null;

  const label = BREADCRUMB_LABELS[pathname];
  if (!label) return null;

  return (
    <div
      className="h-10 flex items-center px-8 gap-2 text-xs border-b"
      style={{ borderColor: "var(--border)", color: "var(--text-dim)" }}
    >
      <Link href="/dashboard" className="hover:text-white transition-colors" style={{ color: "var(--text-dim)" }}>
        Dashboard
      </Link>
      <ChevronRight size={12} />
      <span style={{ color: "var(--text-muted)" }}>{label}</span>
    </div>
  );
}

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [drawerOpen, setDrawerOpen] = useState(false);

  return (
    <div className="min-h-screen flex" style={{ background: "var(--bg)", color: "var(--text)" }}>
      {/* ── Sidebar ───────────────────────────────────────────────────────── */}
      <aside
        className="hidden md:flex flex-col w-56 shrink-0 border-r pt-0"
        style={{ borderColor: "var(--border)", background: "var(--surface)" }}
      >
        {/* Logo strip */}
        <div className="h-14 flex items-center px-5 border-b" style={{ borderColor: "var(--border)" }}>
          <Link href="/" className="flex items-center gap-2 font-bold text-sm">
            <span
              className="flex items-center justify-center w-6 h-6 rounded"
              style={{ background: "linear-gradient(135deg,#f59e0b,#a78bfa)" }}
            >
              <Zap size={13} color="#000" fill="#000" />
            </span>
            <span className="text-white">Hermes</span>
            <span style={{ color: "var(--amber)" }}>Cloud</span>
          </Link>
        </div>

        {/* Nav items */}
        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
            const active = isNavItemActive(href, pathname);
            return (
              <Link
                key={href}
                href={href}
                className="flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors"
                style={{
                  background: active ? "rgba(245,158,11,0.10)" : "transparent",
                  color: active ? "var(--amber)" : "var(--text-muted)",
                  borderLeft: active ? "2px solid var(--amber)" : "2px solid transparent",
                }}
              >
                <Icon size={16} />
                {label}
              </Link>
            );
          })}
        </nav>

        {/* Footer link */}
        <div className="px-5 py-4 border-t" style={{ borderColor: "var(--border)" }}>
          <Link href="/" className="flex items-center gap-2 text-xs" style={{ color: "var(--text-dim)" }}>
            <BookOpen size={13} />
            Back to docs
          </Link>
        </div>
      </aside>

      {/* ── Mobile slide-out drawer backdrop ──────────────────────────────── */}
      {drawerOpen && (
        <div
          className="fixed inset-0 z-30 md:hidden"
          style={{ background: "rgba(0,0,0,0.55)" }}
          onClick={() => setDrawerOpen(false)}
        />
      )}

      {/* ── Mobile slide-out drawer ────────────────────────────────────────── */}
      <div
        className="fixed inset-y-0 left-0 z-40 w-64 flex flex-col md:hidden transition-transform duration-200"
        style={{
          background: "var(--surface)",
          borderRight: "1px solid var(--border)",
          transform: drawerOpen ? "translateX(0)" : "translateX(-100%)",
        }}
      >
        {/* Drawer header */}
        <div className="h-14 flex items-center justify-between px-5 border-b" style={{ borderColor: "var(--border)" }}>
          <Link href="/" onClick={() => setDrawerOpen(false)} className="flex items-center gap-2 font-bold text-sm">
            <span
              className="flex items-center justify-center w-6 h-6 rounded"
              style={{ background: "linear-gradient(135deg,#f59e0b,#a78bfa)" }}
            >
              <Zap size={13} color="#000" fill="#000" />
            </span>
            <span className="text-white">Hermes Cloud</span>
          </Link>
          <button onClick={() => setDrawerOpen(false)} style={{ color: "var(--text-dim)" }}>
            <X size={18} />
          </button>
        </div>

        {/* Drawer nav */}
        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
            const active = isNavItemActive(href, pathname);
            return (
              <Link
                key={href}
                href={href}
                onClick={() => setDrawerOpen(false)}
                className="flex items-center gap-3 px-3 py-2.5 rounded-md text-sm font-medium transition-colors"
                style={{
                  background: active ? "rgba(245,158,11,0.10)" : "transparent",
                  color: active ? "var(--amber)" : "var(--text-muted)",
                  borderLeft: active ? "2px solid var(--amber)" : "2px solid transparent",
                }}
              >
                <Icon size={16} />
                {label}
              </Link>
            );
          })}
        </nav>

        {/* Drawer footer */}
        <div className="px-5 py-4 border-t" style={{ borderColor: "var(--border)" }}>
          <Link href="/" className="flex items-center gap-2 text-xs" style={{ color: "var(--text-dim)" }}>
            <BookOpen size={13} />
            Back to docs
          </Link>
        </div>
      </div>

      {/* ── Main content ──────────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Mobile top bar */}
        <header
          className="md:hidden h-14 flex items-center justify-between px-5 border-b"
          style={{ borderColor: "var(--border)", background: "var(--surface)" }}
        >
          <button onClick={() => setDrawerOpen(true)} style={{ color: "var(--text-muted)" }} aria-label="Open menu">
            <Menu size={20} />
          </button>
          <Link href="/" className="flex items-center gap-2 font-bold text-sm">
            <span
              className="flex items-center justify-center w-6 h-6 rounded"
              style={{ background: "linear-gradient(135deg,#f59e0b,#a78bfa)" }}
            >
              <Zap size={13} color="#000" fill="#000" />
            </span>
            <span className="text-white">Hermes Cloud</span>
          </Link>
          {/* Spacer to keep logo centered */}
          <div style={{ width: 20 }} />
        </header>

        {/* Breadcrumb (desktop only — rendered above main content) */}
        <div className="hidden md:block">
          <Breadcrumb pathname={pathname} />
        </div>

        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
