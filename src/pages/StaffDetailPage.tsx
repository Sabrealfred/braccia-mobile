import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  Mail,
  Shield,
  ShieldOff,
  Briefcase,
  Users,
  Phone,
  Building2,
  Clock,
  Key,
} from "lucide-react";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { formatCurrency, formatRelativeDate } from "../lib/utils";
import { Avatar } from "../components/ui/Avatar";
import { Badge } from "../components/ui/Badge";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Skeleton, ListSkeleton } from "../components/ui/Skeleton";

// ---------------------------------------------------------------------------
// staff_users row shape (matches matwal-premium Supabase schema)
// ---------------------------------------------------------------------------

interface StaffUser {
  id: string;
  user_id: string;
  email: string;
  full_name: string;
  role: string;
  department: string | null;
  phone: string | null;
  avatar_url: string | null;
  is_active: boolean;
  permissions: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
  organization_id: string | null;
  last_login_at: string | null;
}

interface DealRow {
  id: string;
  name: string;
  stage: string;
  deal_value: number | null;
  updated_at: string;
  client_id: string | null;
}

interface ClientRow {
  id: string;
  name: string;
  full_name: string | null;
  status: string | null;
  client_type: string | null;
  updated_at: string;
}

// ---------------------------------------------------------------------------
// Stage helpers
// ---------------------------------------------------------------------------

type StageBadgeVariant =
  | "default"
  | "gold"
  | "success"
  | "warning"
  | "danger"
  | "info"
  | "outline";

function stageBadgeVariant(stage: string): StageBadgeVariant {
  switch (stage) {
    case "sourcing":
      return "default";
    case "nda":
      return "info";
    case "dd":
      return "warning";
    case "negotiation":
      return "gold";
    case "legal":
      return "outline";
    case "closed_won":
      return "success";
    case "closed_lost":
      return "danger";
    default:
      return "default";
  }
}

function stageLabel(stage: string): string {
  switch (stage) {
    case "sourcing":
      return "Sourcing";
    case "nda":
      return "NDA";
    case "dd":
      return "Due Diligence";
    case "negotiation":
      return "Negotiation";
    case "legal":
      return "Legal";
    case "closed_won":
      return "Closed Won";
    case "closed_lost":
      return "Closed Lost";
    default:
      return stage;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function isAdmin(staff: StaffUser): boolean {
  if (staff.role === "admin") return true;
  if (
    staff.permissions &&
    typeof staff.permissions === "object" &&
    "admin" in staff.permissions &&
    staff.permissions.admin
  )
    return true;
  return false;
}

// ---------------------------------------------------------------------------
// Data hooks
// ---------------------------------------------------------------------------

function useStaffMember(id: string) {
  return useQuery<StaffUser>({
    queryKey: ["staff", "detail", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("staff_users")
        .select("*")
        .eq("id", id)
        .single();
      if (error) throw error;
      return data as StaffUser;
    },
    enabled: !!id,
  });
}

function useDealCount(userId: string) {
  return useQuery<number>({
    queryKey: ["staff", "dealCount", userId],
    queryFn: async () => {
      const { count, error } = await supabase
        .from("deals")
        .select("id", { count: "exact", head: true })
        .eq("lead_consultant", userId);
      if (error) throw error;
      return count ?? 0;
    },
    enabled: !!userId,
  });
}

function useClientCount(userId: string) {
  return useQuery<number>({
    queryKey: ["staff", "clientCount", userId],
    queryFn: async () => {
      const { count, error } = await supabase
        .from("clients")
        .select("id", { count: "exact", head: true })
        .eq("assigned_consultant", userId);
      if (error) throw error;
      return count ?? 0;
    },
    enabled: !!userId,
  });
}

function useRecentDeals(userId: string) {
  return useQuery<DealRow[]>({
    queryKey: ["staff", "recentDeals", userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("deals")
        .select("*")
        .eq("lead_consultant", userId)
        .order("updated_at", { ascending: false })
        .limit(5);
      if (error) throw error;
      return (data ?? []) as DealRow[];
    },
    enabled: !!userId,
  });
}

function useRecentClients(userId: string) {
  return useQuery<ClientRow[]>({
    queryKey: ["staff", "recentClients", userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("clients")
        .select("*")
        .eq("assigned_consultant", userId)
        .order("updated_at", { ascending: false })
        .limit(5);
      if (error) throw error;
      return (data ?? []) as ClientRow[];
    },
    enabled: !!userId,
  });
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

function MiniStatCard({
  value,
  label,
  loading,
}: {
  value: number;
  label: string;
  loading: boolean;
}) {
  return (
    <MobileCard className="flex-1 flex flex-col items-center gap-1 py-3">
      {loading ? (
        <Skeleton className="h-7 w-10" />
      ) : (
        <span
          className="text-xl font-bold tabular-nums font-serif"
          style={{ color: "var(--text-primary)" }}
        >
          {value}
        </span>
      )}
      <span
        className="text-[10px] font-semibold uppercase tracking-wider text-center"
        style={{ color: "var(--text-muted)" }}
      >
        {label}
      </span>
    </MobileCard>
  );
}

function DealRowItem({
  deal,
  onTap,
}: {
  deal: DealRow;
  onTap: () => void;
}) {
  return (
    <button
      onClick={onTap}
      className="flex items-center gap-3 w-full px-4 py-3 text-left transition-colors active:bg-[var(--bg-muted)]"
      style={{ borderBottom: "1px solid var(--border-light)" }}
    >
      {/* Deal icon */}
      <div
        className="w-10 h-10 rounded-full flex items-center justify-center shrink-0"
        style={{
          background: "color-mix(in srgb, var(--gold) 15%, transparent)",
          color: "var(--text-gold)",
        }}
      >
        <Briefcase size={18} />
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <p
          className="text-sm font-semibold truncate"
          style={{ color: "var(--text-primary)" }}
        >
          {deal.name}
        </p>
        {deal.updated_at && (
          <p
            className="text-xs truncate mt-0.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Updated {formatRelativeDate(deal.updated_at)}
          </p>
        )}
      </div>

      {/* Right side */}
      <div className="flex flex-col items-end gap-1 shrink-0">
        {deal.deal_value != null && (
          <span
            className="text-sm font-semibold tabular-nums"
            style={{ color: "var(--text-primary)" }}
          >
            {formatCurrency(deal.deal_value)}
          </span>
        )}
        <Badge variant={stageBadgeVariant(deal.stage)}>
          {stageLabel(deal.stage)}
        </Badge>
      </div>
    </button>
  );
}

function ClientRowItem({
  client,
  onTap,
}: {
  client: ClientRow;
  onTap: () => void;
}) {
  const displayName = client.full_name || client.name || "Unnamed";
  const [firstName = "", lastName = ""] = displayName.split(" ");

  return (
    <button
      onClick={onTap}
      className="flex items-center gap-3 w-full px-4 py-3 text-left transition-colors active:bg-[var(--bg-muted)]"
      style={{ borderBottom: "1px solid var(--border-light)" }}
    >
      <Avatar firstName={firstName} lastName={lastName} size="md" />

      <div className="flex-1 min-w-0">
        <p
          className="text-sm font-semibold truncate"
          style={{ color: "var(--text-primary)" }}
        >
          {displayName}
        </p>
        <p
          className="text-xs truncate mt-0.5"
          style={{ color: "var(--text-secondary)" }}
        >
          {[client.client_type, client.status].filter(Boolean).join(" \u00B7 ") ||
            "Client"}
        </p>
      </div>
    </button>
  );
}

function HeroSkeleton() {
  return (
    <div className="flex flex-col items-center gap-3 px-4 pt-4 pb-6">
      <Skeleton className="w-16 h-16 rounded-full" />
      <Skeleton className="h-6 w-40" />
      <Skeleton className="h-4 w-52" />
      <div className="flex gap-2 mt-1">
        <Skeleton className="h-5 w-16 rounded-full" />
      </div>
    </div>
  );
}

function DealsSkeleton() {
  return (
    <div>
      {Array.from({ length: 3 }).map((_, i) => (
        <div
          key={i}
          className="flex items-center gap-3 px-4 py-3"
          style={{ borderBottom: "1px solid var(--border-light)" }}
        >
          <Skeleton className="w-10 h-10 rounded-full" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-32" />
            <Skeleton className="h-3 w-24" />
          </div>
          <div className="space-y-2">
            <Skeleton className="h-4 w-16 ml-auto" />
            <Skeleton className="h-4 w-20 ml-auto" />
          </div>
        </div>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Permissions display
// ---------------------------------------------------------------------------

function PermissionsCard({
  permissions,
}: {
  permissions: Record<string, unknown> | null;
}) {
  if (!permissions || Object.keys(permissions).length === 0) return null;

  return (
    <div className="mt-6">
      <SectionTitle>Permissions</SectionTitle>
      <MobileCard className="mx-4">
        <div className="flex flex-wrap gap-2">
          {Object.entries(permissions).map(([key, value]) => (
            <div key={key} className="flex items-center gap-1.5">
              <Key size={10} style={{ color: "var(--text-muted)" }} />
              <span
                className="text-xs font-medium"
                style={{ color: "var(--text-secondary)" }}
              >
                {key}
              </span>
              {typeof value === "boolean" ? (
                <Badge variant={value ? "success" : "danger"}>
                  {value ? "Yes" : "No"}
                </Badge>
              ) : (
                <Badge variant="default">
                  {String(value)}
                </Badge>
              )}
            </div>
          ))}
        </div>
      </MobileCard>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

export function StaffDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();

  const staffQuery = useStaffMember(id!);
  const member = staffQuery.data;

  // Use user_id for relationship queries (deals.lead_consultant, clients.assigned_consultant)
  const staffUserId = member?.user_id ?? "";

  const dealCount = useDealCount(staffUserId);
  const clientCount = useClientCount(staffUserId);
  const recentDeals = useRecentDeals(staffUserId);
  const recentClients = useRecentClients(staffUserId);

  const isCurrentUser = member?.user_id === user?.id;

  const statsLoading = dealCount.isLoading || clientCount.isLoading;

  // Split full_name for Avatar
  const [firstName = "", lastName = ""] = (member?.full_name || "").split(" ");

  return (
    <div
      className="min-h-screen pb-24"
      style={{ background: "var(--bg-primary)" }}
    >
      {/* Header */}
      <PageHeader
        title={member ? member.full_name : "Staff Member"}
        back
      />

      {/* Hero */}
      {staffQuery.isLoading ? (
        <HeroSkeleton />
      ) : staffQuery.isError ? (
        <div className="px-4 py-12 text-center">
          <Users
            size={40}
            style={{ color: "var(--text-muted)", margin: "0 auto" }}
          />
          <p
            className="text-sm mt-3"
            style={{ color: "var(--text-muted)" }}
          >
            {staffQuery.error instanceof Error
              ? staffQuery.error.message
              : "Failed to load staff member"}
          </p>
        </div>
      ) : member ? (
        <>
          {/* Hero card */}
          <div className="flex flex-col items-center gap-2 px-4 pt-2 pb-5">
            <Avatar
              firstName={firstName}
              lastName={lastName}
              src={member.avatar_url ?? undefined}
              size="xl"
            />

            <h2
              className="text-xl font-bold font-serif mt-1"
              style={{ color: "var(--text-primary)" }}
            >
              {member.full_name}
            </h2>

            {member.email && (
              <div className="flex items-center gap-1.5">
                <Mail size={14} style={{ color: "var(--text-muted)" }} />
                <span
                  className="text-sm"
                  style={{ color: "var(--text-secondary)" }}
                >
                  {member.email}
                </span>
              </div>
            )}

            {member.phone && (
              <div className="flex items-center gap-1.5">
                <Phone size={14} style={{ color: "var(--text-muted)" }} />
                <span
                  className="text-sm"
                  style={{ color: "var(--text-secondary)" }}
                >
                  {member.phone}
                </span>
              </div>
            )}

            {/* Badges */}
            <div className="flex items-center gap-2 mt-1 flex-wrap justify-center">
              {member.role && (
                <Badge variant="default">{member.role}</Badge>
              )}
              {member.department && (
                <Badge variant="outline">
                  <Building2 size={9} />
                  {member.department}
                </Badge>
              )}
              {isAdmin(member) && (
                <Badge variant="info">
                  <Shield size={9} />
                  Admin
                </Badge>
              )}
              {!member.is_active && (
                <Badge variant="warning">
                  <ShieldOff size={9} />
                  Inactive
                </Badge>
              )}
              {isCurrentUser && <Badge variant="gold">You</Badge>}
            </div>

            {/* Last login */}
            {member.last_login_at && (
              <div className="flex items-center gap-1.5 mt-1">
                <Clock size={12} style={{ color: "var(--text-muted)" }} />
                <span
                  className="text-xs"
                  style={{ color: "var(--text-muted)" }}
                >
                  Last login {formatRelativeDate(member.last_login_at)}
                </span>
              </div>
            )}
          </div>

          {/* Stats row */}
          <div className="flex gap-3 px-4">
            <MiniStatCard
              value={dealCount.data ?? 0}
              label="Deals"
              loading={statsLoading}
            />
            <MiniStatCard
              value={clientCount.data ?? 0}
              label="Clients"
              loading={statsLoading}
            />
          </div>

          {/* Recent Deals */}
          <div className="mt-6">
            <SectionTitle count={recentDeals.data?.length}>
              Recent Deals
            </SectionTitle>

            <MobileCard noPadding className="mx-4 overflow-hidden">
              {recentDeals.isLoading ? (
                <DealsSkeleton />
              ) : recentDeals.data && recentDeals.data.length > 0 ? (
                recentDeals.data.map((deal) => (
                  <DealRowItem
                    key={deal.id}
                    deal={deal}
                    onTap={() => navigate(`/deals/${deal.id}`)}
                  />
                ))
              ) : (
                <div className="px-4 py-8 text-center">
                  <p
                    className="text-sm"
                    style={{ color: "var(--text-muted)" }}
                  >
                    No deals assigned
                  </p>
                </div>
              )}
            </MobileCard>
          </div>

          {/* Recent Clients */}
          <div className="mt-6">
            <SectionTitle count={recentClients.data?.length}>
              Recent Clients
            </SectionTitle>

            <MobileCard noPadding className="mx-4 overflow-hidden">
              {recentClients.isLoading ? (
                <ListSkeleton count={3} />
              ) : recentClients.data && recentClients.data.length > 0 ? (
                recentClients.data.map((client) => (
                  <ClientRowItem
                    key={client.id}
                    client={client}
                    onTap={() => navigate(`/clients/${client.id}`)}
                  />
                ))
              ) : (
                <div className="px-4 py-8 text-center">
                  <p
                    className="text-sm"
                    style={{ color: "var(--text-muted)" }}
                  >
                    No clients managed
                  </p>
                </div>
              )}
            </MobileCard>
          </div>

          {/* Permissions */}
          <PermissionsCard permissions={member.permissions} />
        </>
      ) : null}
    </div>
  );
}
