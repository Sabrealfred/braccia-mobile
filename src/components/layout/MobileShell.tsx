import { Outlet, useLocation, useNavigate } from "react-router-dom";
import {
  LayoutDashboard,
  Users,
  Building2,
  Handshake,
  UserCog,
} from "lucide-react";
import { useAuth } from "../../providers/AuthProvider";

const navItems = [
  { path: "/", icon: LayoutDashboard, label: "Home" },
  { path: "/contacts", icon: Users, label: "Contacts" },
  { path: "/companies", icon: Building2, label: "Companies" },
  { path: "/deals", icon: Handshake, label: "Deals" },
  { path: "/staff", icon: UserCog, label: "Staff" },
];

export function MobileShell() {
  const location = useLocation();
  const navigate = useNavigate();
  const { sale } = useAuth();

  const currentTab = navItems.findIndex((item) => {
    if (item.path === "/") return location.pathname === "/";
    return location.pathname.startsWith(item.path);
  });

  return (
    <div className="flex flex-col min-h-[100dvh]">
      {/* Header */}
      <header
        className="safe-top sticky top-0 z-40 glass"
        style={{ background: "var(--bg-header)" }}
      >
        <div className="flex items-center justify-between px-4 h-[var(--nav-height)]">
          <div className="flex items-center gap-2">
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold"
              style={{ background: "var(--gold)", color: "var(--white)" }}
            >
              BC
            </div>
            <span
              className="font-serif text-lg font-semibold"
              style={{ color: "var(--ivory)" }}
            >
              Braccia Capital
            </span>
          </div>
          {sale && (
            <button
              onClick={() => navigate("/settings")}
              className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold"
              style={{
                background: "var(--charcoal-light)",
                color: "var(--gold-light)",
              }}
            >
              {sale.first_name?.charAt(0)}
              {sale.last_name?.charAt(0)}
            </button>
          )}
        </div>
      </header>

      {/* Main content */}
      <main className="flex-1 safe-bottom">
        <Outlet />
      </main>

      {/* Bottom navigation */}
      <nav
        className="fixed bottom-0 left-0 right-0 z-50 glass border-t"
        style={{
          background: "var(--bg-nav)",
          borderColor: "var(--border-light)",
          paddingBottom: "env(safe-area-inset-bottom)",
        }}
      >
        <div className="flex justify-around items-center h-[var(--bottom-nav-height)]">
          {navItems.map((item, idx) => {
            const isActive = idx === currentTab;
            const Icon = item.icon;
            return (
              <button
                key={item.path}
                onClick={() => navigate(item.path)}
                className="flex flex-col items-center justify-center gap-0.5 w-16 py-1 transition-colors"
                style={{
                  color: isActive ? "var(--gold)" : "var(--text-muted)",
                }}
              >
                <Icon
                  size={22}
                  strokeWidth={isActive ? 2.5 : 1.8}
                />
                <span
                  className="text-[10px] font-medium"
                  style={{
                    color: isActive ? "var(--gold)" : "var(--text-muted)",
                  }}
                >
                  {item.label}
                </span>
                {isActive && (
                  <div
                    className="absolute top-0 w-12 h-0.5 rounded-full"
                    style={{ background: "var(--gold)" }}
                  />
                )}
              </button>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
