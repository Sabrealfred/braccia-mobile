import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import {
  Sun,
  Moon,
  Bell,
  Globe,
  LogOut,
  ChevronRight,
  UserPen,
  Shield,
} from "lucide-react";
import { useAuth } from "../providers/AuthProvider";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Avatar } from "../components/ui/Avatar";
import { Badge } from "../components/ui/Badge";

// ---------------------------------------------------------------------------
// Toggle switch component
// ---------------------------------------------------------------------------

function Toggle({
  checked,
  onChange,
}: {
  checked: boolean;
  onChange: (val: boolean) => void;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className="relative shrink-0 transition-colors duration-200"
      style={{
        width: 48,
        height: 28,
        borderRadius: 14,
        background: checked ? "var(--gold)" : "var(--bg-muted)",
        border: "none",
        cursor: "pointer",
        padding: 0,
      }}
    >
      <span
        className="block rounded-full shadow transition-transform duration-200"
        style={{
          width: 22,
          height: 22,
          background: "white",
          position: "absolute",
          top: 3,
          left: 3,
          transform: checked ? "translateX(20px)" : "translateX(0)",
        }}
      />
    </button>
  );
}

// ---------------------------------------------------------------------------
// Settings row component
// ---------------------------------------------------------------------------

function SettingRow({
  icon,
  label,
  description,
  right,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  description?: string;
  right?: React.ReactNode;
  onClick?: () => void;
}) {
  const Wrapper = onClick ? "button" : "div";
  return (
    <Wrapper
      {...(onClick ? { onClick, type: "button" as const } : {})}
      className="flex items-center gap-3 w-full px-4 py-3.5 active:bg-[var(--bg-muted)] transition-colors text-left"
      style={{
        borderBottom: "1px solid var(--border-light)",
        background: "transparent",
        border: "none",
        borderBottomWidth: 1,
        borderBottomStyle: "solid",
        borderBottomColor: "var(--border-light)",
        cursor: onClick ? "pointer" : "default",
      }}
    >
      {/* Icon */}
      <div
        className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
        style={{
          background: "color-mix(in srgb, var(--gold) 12%, transparent)",
          color: "var(--text-gold)",
        }}
      >
        {icon}
      </div>

      {/* Label + description */}
      <div className="flex-1 min-w-0">
        <p
          className="text-sm font-medium"
          style={{ color: "var(--text-primary)" }}
        >
          {label}
        </p>
        {description && (
          <p
            className="text-xs mt-0.5"
            style={{ color: "var(--text-muted)" }}
          >
            {description}
          </p>
        )}
      </div>

      {/* Right side */}
      {right && <div className="shrink-0">{right}</div>}
    </Wrapper>
  );
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

const THEME_KEY = "braccia-theme";

function getStoredDarkMode(): boolean {
  try {
    const stored = localStorage.getItem(THEME_KEY);
    if (stored === "dark") return true;
    if (stored === "light") return false;
    // Default: check system preference
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  } catch {
    return false;
  }
}

function applyDarkMode(dark: boolean) {
  if (dark) {
    document.documentElement.classList.add("dark");
  } else {
    document.documentElement.classList.remove("dark");
  }
  try {
    localStorage.setItem(THEME_KEY, dark ? "dark" : "light");
  } catch {
    // localStorage may be unavailable
  }
}

function getInitialsFromFullName(fullName: string): { first: string; last: string } {
  const parts = fullName.trim().split(/\s+/);
  return {
    first: parts[0] || "",
    last: parts.length > 1 ? parts[parts.length - 1] : "",
  };
}

const roleLabelMap: Record<string, string> = {
  admin: "Admin",
  consultant: "Consultant",
  manager: "Manager",
  analyst: "Analyst",
  user: "User",
  partner: "Partner",
  director: "Director",
};

const roleVariantMap: Record<string, "gold" | "info" | "success" | "warning" | "default"> = {
  admin: "gold",
  partner: "gold",
  director: "gold",
  manager: "info",
  consultant: "success",
  analyst: "info",
  user: "default",
};

export function SettingsPage() {
  const { user, sale, signOut } = useAuth();
  const navigate = useNavigate();

  const [darkMode, setDarkMode] = useState(getStoredDarkMode);
  const [notifications, setNotifications] = useState(true);

  // Apply dark mode on mount (in case it was stored but not yet applied)
  useEffect(() => {
    applyDarkMode(darkMode);
  }, [darkMode]);

  const handleDarkModeToggle = useCallback((val: boolean) => {
    setDarkMode(val);
    applyDarkMode(val);
  }, []);

  const handleSignOut = useCallback(async () => {
    const confirmed = window.confirm(
      "Are you sure you want to sign out?"
    );
    if (!confirmed) return;
    await signOut();
    navigate("/login");
  }, [signOut, navigate]);

  // Derive display values from user_profiles shape
  const fullName = sale?.full_name || `${sale?.first_name || ""} ${sale?.last_name || ""}`.trim() || "Unknown User";
  const { first: avatarFirst, last: avatarLast } = getInitialsFromFullName(fullName);
  const email = sale?.email || user?.email || "";
  const role = sale?.role || "user";
  const isActive = sale?.is_active ?? true;

  return (
    <div
      className="min-h-screen pb-24"
      style={{ background: "var(--bg-primary)" }}
    >
      <PageHeader title="Settings" />

      {/* ---- Profile Section ---- */}
      <SectionTitle>Profile</SectionTitle>

      <MobileCard className="mx-4">
        <div className="flex items-center gap-4">
          <Avatar
            firstName={avatarFirst}
            lastName={avatarLast}
            src={sale?.avatar_url ?? undefined}
            size="xl"
          />
          <div className="flex-1 min-w-0">
            <h2
              className="text-lg font-semibold font-serif truncate"
              style={{ color: "var(--text-primary)" }}
            >
              {fullName}
            </h2>
            {email && (
              <p
                className="text-sm truncate mt-0.5"
                style={{ color: "var(--text-secondary)" }}
              >
                {email}
              </p>
            )}
            <div className="flex items-center gap-2 mt-2">
              <Badge variant={roleVariantMap[role] ?? "default"}>
                {roleLabelMap[role] ?? role}
              </Badge>
              {!isActive && (
                <Badge variant="danger">Inactive</Badge>
              )}
            </div>
          </div>
        </div>

        {/* Edit Profile button */}
        <button
          type="button"
          onClick={() => {
            if (sale?.id) {
              navigate(`/staff/${sale.id}`);
            }
          }}
          className="w-full mt-4 flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-medium transition-colors active:opacity-80"
          style={{
            background: "color-mix(in srgb, var(--gold) 12%, transparent)",
            color: "var(--text-gold)",
            border: "none",
            cursor: "pointer",
          }}
        >
          <UserPen size={16} />
          Edit Profile
        </button>
      </MobileCard>

      {/* ---- Preferences Section ---- */}
      <SectionTitle>Preferences</SectionTitle>

      <MobileCard noPadding className="mx-4 overflow-hidden">
        <SettingRow
          icon={darkMode ? <Moon size={18} /> : <Sun size={18} />}
          label="Dark Mode"
          description={darkMode ? "On" : "Off"}
          right={
            <Toggle checked={darkMode} onChange={handleDarkModeToggle} />
          }
        />
        <SettingRow
          icon={<Bell size={18} />}
          label="Notifications"
          description={notifications ? "Enabled" : "Disabled"}
          right={
            <Toggle
              checked={notifications}
              onChange={setNotifications}
            />
          }
        />
        <SettingRow
          icon={<Globe size={18} />}
          label="Language"
          description="English"
          right={
            <ChevronRight
              size={18}
              style={{ color: "var(--text-muted)" }}
            />
          }
          onClick={() => {
            // Placeholder -- language selector not yet implemented
          }}
        />
      </MobileCard>

      {/* ---- About Section ---- */}
      <SectionTitle>About</SectionTitle>

      <MobileCard className="mx-4">
        <div className="flex items-center gap-3 mb-3">
          <div
            className="w-10 h-10 rounded-full flex items-center justify-center shrink-0"
            style={{
              background: "var(--gold)",
              boxShadow: "0 2px 12px rgba(184, 134, 11, 0.25)",
            }}
          >
            <span
              className="font-serif text-sm font-normal text-white"
              style={{ letterSpacing: 0.5 }}
            >
              BC
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <p
              className="text-sm font-semibold font-serif"
              style={{ color: "var(--text-primary)" }}
            >
              Braccia Capital{" "}
              <span style={{ color: "var(--gold)" }}>CRM</span>
            </p>
            <p
              className="text-xs mt-0.5"
              style={{ color: "var(--text-muted)" }}
            >
              Deal Management Platform
            </p>
          </div>
        </div>

        <div
          className="rounded-xl p-3 space-y-2"
          style={{ background: "var(--bg-muted)" }}
        >
          <div className="flex items-center justify-between">
            <span
              className="text-xs font-medium"
              style={{ color: "var(--text-muted)" }}
            >
              Version
            </span>
            <span
              className="text-xs font-semibold"
              style={{ color: "var(--text-primary)" }}
            >
              1.0.0
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span
              className="text-xs font-medium"
              style={{ color: "var(--text-muted)" }}
            >
              Build
            </span>
            <span
              className="text-xs font-semibold"
              style={{ color: "var(--text-primary)" }}
            >
              2026.03.17
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span
              className="text-xs font-medium"
              style={{ color: "var(--text-muted)" }}
            >
              Environment
            </span>
            <Badge variant="outline">
              {import.meta.env.MODE ?? "production"}
            </Badge>
          </div>
        </div>
      </MobileCard>

      {/* ---- Danger Zone ---- */}
      <SectionTitle>Danger Zone</SectionTitle>

      <MobileCard noPadding className="mx-4 overflow-hidden">
        <SettingRow
          icon={
            <Shield
              size={18}
              style={{ color: "var(--danger)" }}
            />
          }
          label="Privacy Policy"
          right={
            <ChevronRight
              size={18}
              style={{ color: "var(--text-muted)" }}
            />
          }
          onClick={() => {
            // Placeholder
          }}
        />
        <div
          style={{ borderBottom: "none" }}
        >
          <SettingRow
            icon={
              <LogOut
                size={18}
                style={{ color: "var(--danger)" }}
              />
            }
            label="Sign Out"
            description="End your current session"
            right={
              <ChevronRight
                size={18}
                style={{ color: "var(--danger)" }}
              />
            }
            onClick={handleSignOut}
          />
        </div>
      </MobileCard>

      {/* Sign out big button */}
      <div className="px-4 mt-6">
        <button
          type="button"
          onClick={handleSignOut}
          className="w-full flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-semibold transition-colors active:opacity-80"
          style={{
            background: "color-mix(in srgb, var(--danger) 12%, transparent)",
            color: "var(--danger)",
            border: "1px solid color-mix(in srgb, var(--danger) 25%, transparent)",
            cursor: "pointer",
          }}
        >
          <LogOut size={18} />
          Sign Out
        </button>
      </div>

      {/* Footer */}
      <p
        className="text-center mt-8 mb-4 text-xs"
        style={{ color: "var(--text-muted)" }}
      >
        Braccia Capital &middot; Confidential
      </p>
    </div>
  );
}
