import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Mail, Shield, ShieldOff, Briefcase, Users } from "lucide-react";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { formatCurrency } from "../lib/utils";
import { Avatar } from "../components/ui/Avatar";
import { Badge } from "../components/ui/Badge";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Skeleton, ListSkeleton } from "../components/ui/Skeleton";
import type { Sale, Deal, Contact } from "../types";

// ---------------------------------------------------------------------------
// Stage helpers (matching DashboardPage)
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
// Data hooks
// ---------------------------------------------------------------------------

function useStaffMember(id: string) {
  return useQuery<Sale>({
    queryKey: ["staff", "detail", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("sales")
        .select("*")
        .eq("id", id)
        .single();
      if (error) throw error;
      return data;
    },
    enabled: !!id,
  });
}

function useDealCount(salesId: string) {
  return useQuery<number>({
    queryKey: ["staff", "dealCount", salesId],
    queryFn: async () => {
      const { count, error } = await supabase
        .from("deals")
        .select("id", { count: "exact", head: true })
        .eq("sales_id", salesId);
      if (error) throw error;
      return count ?? 0;
    },
    enabled: !!salesId,
  });
}

function useContactCount(salesId: string) {
  return useQuery<number>({
    queryKey: ["staff", "contactCount", salesId],
    queryFn: async () => {
      const { count, error } = await supabase
        .from("contacts")
        .select("id", { count: "exact", head: true })
        .eq("sales_id", salesId);
      if (error) throw error;
      return count ?? 0;
    },
    enabled: !!salesId,
  });
}

function useNoteCount(salesId: string) {
  return useQuery<number>({
    queryKey: ["staff", "noteCount", salesId],
    queryFn: async () => {
      const { count, error } = await supabase
        .from("contactNotes")
        .select("id", { count: "exact", head: true })
        .eq("sales_id", salesId);
      if (error) throw error;
      return count ?? 0;
    },
    enabled: !!salesId,
  });
}

function useRecentDeals(salesId: string) {
  return useQuery<(Deal & { companies: { name: string } | null })[]>({
    queryKey: ["staff", "recentDeals", salesId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("deals")
        .select("*, companies(name)")
        .eq("sales_id", salesId)
        .order("updated_at", { ascending: false })
        .limit(5);
      if (error) throw error;
      return (data ?? []) as (Deal & { companies: { name: string } | null })[];
    },
    enabled: !!salesId,
  });
}

function useRecentContacts(salesId: string) {
  return useQuery<Contact[]>({
    queryKey: ["staff", "recentContacts", salesId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("contacts")
        .select("*")
        .eq("sales_id", salesId)
        .order("last_seen", { ascending: false })
        .limit(5);
      if (error) throw error;
      return (data ?? []) as Contact[];
    },
    enabled: !!salesId,
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

function DealRow({
  deal,
  onTap,
}: {
  deal: Deal & { companies: { name: string } | null };
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
        <p
          className="text-xs truncate mt-0.5"
          style={{ color: "var(--text-secondary)" }}
        >
          {deal.companies?.name ?? "No company"}
        </p>
      </div>

      {/* Right side */}
      <div className="flex flex-col items-end gap-1 shrink-0">
        <span
          className="text-sm font-semibold tabular-nums"
          style={{ color: "var(--text-primary)" }}
        >
          {formatCurrency(deal.amount)}
        </span>
        <Badge variant={stageBadgeVariant(deal.stage)}>
          {stageLabel(deal.stage)}
        </Badge>
      </div>
    </button>
  );
}

function ContactRow({
  contact,
  onTap,
}: {
  contact: Contact;
  onTap: () => void;
}) {
  return (
    <button
      onClick={onTap}
      className="flex items-center gap-3 w-full px-4 py-3 text-left transition-colors active:bg-[var(--bg-muted)]"
      style={{ borderBottom: "1px solid var(--border-light)" }}
    >
      <Avatar
        firstName={contact.first_name}
        lastName={contact.last_name}
        src={contact.avatar?.src}
        size="md"
      />

      <div className="flex-1 min-w-0">
        <p
          className="text-sm font-semibold truncate"
          style={{ color: "var(--text-primary)" }}
        >
          {contact.first_name} {contact.last_name}
        </p>
        <p
          className="text-xs truncate mt-0.5"
          style={{ color: "var(--text-secondary)" }}
        >
          {[contact.title, contact.company_name].filter(Boolean).join(" · ") ||
            "No title"}
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
// Main page
// ---------------------------------------------------------------------------

export function StaffDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { sale: currentSale } = useAuth();

  const staffQuery = useStaffMember(id!);
  const dealCount = useDealCount(id!);
  const contactCount = useContactCount(id!);
  const noteCount = useNoteCount(id!);
  const recentDeals = useRecentDeals(id!);
  const recentContacts = useRecentContacts(id!);

  const member = staffQuery.data;
  const isCurrentUser = member?.id === currentSale?.id;

  const statsLoading =
    dealCount.isLoading || contactCount.isLoading || noteCount.isLoading;

  return (
    <div
      className="min-h-screen pb-24"
      style={{ background: "var(--bg-primary)" }}
    >
      {/* Header */}
      <PageHeader
        title={
          member
            ? `${member.first_name} ${member.last_name}`
            : "Staff Member"
        }
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
              firstName={member.first_name}
              lastName={member.last_name}
              src={member.avatar?.src}
              size="xl"
            />

            <h2
              className="text-xl font-bold font-serif mt-1"
              style={{ color: "var(--text-primary)" }}
            >
              {member.first_name} {member.last_name}
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

            {/* Badges */}
            <div className="flex items-center gap-2 mt-1 flex-wrap justify-center">
              {member.administrator && (
                <Badge variant="info">
                  <Shield size={9} />
                  Admin
                </Badge>
              )}
              {member.disabled && (
                <Badge variant="warning">
                  <ShieldOff size={9} />
                  Disabled
                </Badge>
              )}
              {isCurrentUser && <Badge variant="gold">You</Badge>}
            </div>
          </div>

          {/* Stats row */}
          <div className="flex gap-3 px-4">
            <MiniStatCard
              value={dealCount.data ?? 0}
              label="Deals"
              loading={statsLoading}
            />
            <MiniStatCard
              value={contactCount.data ?? 0}
              label="Contacts"
              loading={statsLoading}
            />
            <MiniStatCard
              value={noteCount.data ?? 0}
              label="Notes"
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
                  <DealRow
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

          {/* Recent Contacts */}
          <div className="mt-6">
            <SectionTitle count={recentContacts.data?.length}>
              Recent Contacts
            </SectionTitle>

            <MobileCard noPadding className="mx-4 overflow-hidden">
              {recentContacts.isLoading ? (
                <ListSkeleton count={3} />
              ) : recentContacts.data && recentContacts.data.length > 0 ? (
                recentContacts.data.map((contact) => (
                  <ContactRow
                    key={contact.id}
                    contact={contact}
                    onTap={() => navigate(`/contacts/${contact.id}`)}
                  />
                ))
              ) : (
                <div className="px-4 py-8 text-center">
                  <p
                    className="text-sm"
                    style={{ color: "var(--text-muted)" }}
                  >
                    No contacts managed
                  </p>
                </div>
              )}
            </MobileCard>
          </div>
        </>
      ) : null}
    </div>
  );
}
