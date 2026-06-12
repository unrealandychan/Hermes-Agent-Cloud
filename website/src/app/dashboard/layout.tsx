"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Zap, Rocket, Terminal, Settings, BookOpen, LayoutDashboard } from "lucide-react";

const NAV_ITEMS = [
  { href: "/dashboard",          label: "Overview",   icon: LayoutDashboard },
  { href: "/dashboard/deploy",   label: "Deploy",     icon: Rocket },
  { href: "/dashboard/commands", label: "Commands",   icon: Terminal },
  { href: "/dashboard/config",   label: "Config",     icon: Settings },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

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
            const active = pathname === href || (href !== "/dashboard" && pathname.startsWith(href));
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

      {/* ── Main content ──────────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Mobile top bar */}
        <header
          className="md:hidden h-14 flex items-center justify-between px-5 border-b"
          style={{ borderColor: "var(--border)", background: "var(--surface)" }}
        >
          <Link href="/" className="flex items-center gap-2 font-bold text-sm">
            <span
              className="flex items-center justify-center w-6 h-6 rounded"
              style={{ background: "linear-gradient(135deg,#f59e0b,#a78bfa)" }}
            >
              <Zap size={13} color="#000" fill="#000" />
            </span>
            <span className="text-white">Hermes Cloud</span>
          </Link>
          <nav className="flex items-center gap-4 text-xs" style={{ color: "var(--text-muted)" }}>
            {NAV_ITEMS.map(({ href, label }) => (
              <Link
                key={href}
                href={href}
                style={{ color: pathname === href ? "var(--amber)" : undefined }}
              >
                {label}
              </Link>
            ))}
          </nav>
        </header>

        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>
    </div>
  );
}
