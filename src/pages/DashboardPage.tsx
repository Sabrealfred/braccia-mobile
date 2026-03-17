import { useQuery } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { formatCurrency, formatDate } from "../lib/utils";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Badge } from "../components/ui/Badge";
import { Skeleton } from "../components/ui/Skeleton";
import type { Deal, Task } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
}

function formatToday(): string {
  return new Intl.DateTimeFormat("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  }).format(new Date());
}

type StageBadgeVariant = "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline";

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

function priorityLabel(priority: string | undefined): string {
  switch (priority) {
    case "urgent":
      return "Urgent";
    case "high":
      return "High";
    case "medium":
      return "Medium";
    case "low":
      return "Low";
    default:
      return priority || "";
  }
}

function priorityBadgeVariant(priority: string | undefined): StageBadgeVariant {
  switch (priority) {
    case "urgent":
      return "danger";
    case "high":
      return "warning";
    case "medium":
      return "info";
    case "low":
      return "default";
    default:
      return "outline";
  }
}

// ---------------------------------------------------------------------------
// Data hooks — Real matwal-premium Supabase schema
// ---------------------------------------------------------------------------

/** Total clients count (table: clients) */
function useClientCount() {
  return useQuery({
    queryKey: ["dashboard", "clientCount"],
    queryFn: async () => {
      const { count, error } = await supabase
        .from("clients")
        .select("id", { count: "exact", head: true });
      if (error) throw error;
      return count ?? 0;
    },
  });
}

/** Entity count — clients with client_type='entity' serve as companies */
function useEntityCount() {
  return useQuery({
    queryKey: ["dashboard", "entityCount"],
    queryFn: async () => {
      const { count, error } = await supabase
        .from("clients")
        .select("id", { count: "exact", head: true })
        .eq("client_type", "entity");
      if (error) throw error;
      return count ?? 0;
    },
  });
}

/** Active deals stats — is_active=true, sum deal_value for pipeline */
function useDealsStats() {
  return useQuery({
    queryKey: ["dashboard", "dealsStats"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("deals")
        .select("*")
        .eq("is_active", true);
      if (error) throw error;
      const deals = (data ?? []) as Deal[];
      const pipelineValue = deals.reduce(
        (sum, d) => sum + (d.deal_value ?? 0),
        0
      );
      return { activeCount: deals.length, pipelineValue };
    },
  });
}

/** Recent deals — ordered by updated_at desc, limit 5 */
function useRecentDeals() {
  return useQuery({
    queryKey: ["dashboard", "recentDeals"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("deals")
        .select("*")
        .order("updated_at", { ascending: false })
        .limit(5);
      if (error) throw error;
      return (data ?? []) as Deal[];
    },
  });
}

/** Upcoming tasks — no completion_date, ordered by due_date, limit 5 */
function useUpcomingTasks() {
  return useQuery({
    queryKey: ["dashboard", "upcomingTasks"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("tasks")
        .select("*")
        .is("completion_date", null)
        .order("due_date")
        .limit(5);
      if (error) throw error;
      return (data ?? []) as Task[];
    },
  });
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

function StatCard({
  icon,
  value,
  label,
  loading,
}: {
  icon: React.ReactNode;
  value: string;
  label: string;
  loading: boolean;
}) {
  return (
    <MobileCard className="flex flex-col gap-2">
      <div
        className="w-9 h-9 rounded-xl flex items-center justify-center text-lg"
        style={{
          background: "color-mix(in srgb, var(--gold) 12%, transparent)",
          color: "var(--text-gold)",
        }}
      >
        {icon}
      </div>
      {loading ? (
        <Skeleton className="h-7 w-16 mt-1" />
      ) : (
        <span
          className="text-2xl font-bold tracking-tight font-serif"
          style={{ color: "var(--text-primary)" }}
        >
          {value}
        </span>
      )}
      <span
        className="text-xs font-medium"
        style={{ color: "var(--text-muted)" }}
      >
        {label}
      </span>
    </MobileCard>
  );
}

function StatsSkeleton() {
  return (
    <div className="grid grid-cols-2 gap-3 px-4">
      {Array.from({ length: 4 }).map((_, i) => (
        <MobileCard key={i} className="flex flex-col gap-2">
          <Skeleton className="w-9 h-9 rounded-xl" />
          <Skeleton className="h-7 w-16 mt-1" />
          <Skeleton className="h-3 w-20" />
        </MobileCard>
      ))}
    </div>
  );
}

function RecentDealRow({ deal }: { deal: Deal }) {
  return (
    <div
      className="flex items-center gap-3 px-4 py-3 active:bg-[var(--bg-muted)] transition-colors"
      style={{ borderBottom: "1px solid var(--border-light)" }}
    >
      {/* Deal icon */}
      <div
        className="w-10 h-10 rounded-full flex items-center justify-center shrink-0 text-sm"
        style={{
          background: "color-mix(in srgb, var(--gold) 15%, transparent)",
          color: "var(--text-gold)",
        }}
      >
        <svg
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
        </svg>
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
          {deal.stage ? stageLabel(deal.stage) : "No stage"}
        </p>
      </div>

      {/* Right side */}
      <div className="flex flex-col items-end gap-1 shrink-0">
        <span
          className="text-sm font-semibold tabular-nums"
          style={{ color: "var(--text-primary)" }}
        >
          {formatCurrency(deal.deal_value ?? 0)}
        </span>
        <Badge variant={stageBadgeVariant(deal.stage)}>
          {stageLabel(deal.stage)}
        </Badge>
      </div>
    </div>
  );
}

function TaskRow({ task }: { task: Task }) {
  const isOverdue =
    task.due_date && new Date(task.due_date) < new Date();

  return (
    <div
      className="flex items-start gap-3 px-4 py-3 active:bg-[var(--bg-muted)] transition-colors"
      style={{ borderBottom: "1px solid var(--border-light)" }}
    >
      {/* Task type icon */}
      <div
        className="w-10 h-10 rounded-full flex items-center justify-center shrink-0 mt-0.5"
        style={{
          background: isOverdue
            ? "color-mix(in srgb, var(--danger) 12%, transparent)"
            : "var(--bg-muted)",
          color: isOverdue ? "var(--danger)" : "var(--text-secondary)",
        }}
      >
        <svg
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
          <line x1="16" y1="2" x2="16" y2="6" />
          <line x1="8" y1="2" x2="8" y2="6" />
          <line x1="3" y1="10" x2="21" y2="10" />
        </svg>
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <p
          className="text-sm font-medium"
          style={{ color: "var(--text-primary)" }}
        >
          {task.title}
        </p>
        <div className="flex items-center gap-2 mt-1">
          {task.due_date && (
            <span
              className="text-xs shrink-0"
              style={{ color: isOverdue ? "var(--danger)" : "var(--text-muted)" }}
            >
              {isOverdue ? "Overdue — " : ""}
              {formatDate(task.due_date)}
            </span>
          )}
        </div>
      </div>

      {/* Priority badge */}
      {task.priority && (
        <Badge variant={priorityBadgeVariant(task.priority)} className="shrink-0 mt-0.5">
          {priorityLabel(task.priority)}
        </Badge>
      )}
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

function TasksSkeleton() {
  return (
    <div>
      {Array.from({ length: 3 }).map((_, i) => (
        <div
          key={i}
          className="flex items-start gap-3 px-4 py-3"
          style={{ borderBottom: "1px solid var(--border-light)" }}
        >
          <Skeleton className="w-10 h-10 rounded-full" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-48" />
            <Skeleton className="h-3 w-32" />
          </div>
        </div>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

export function DashboardPage() {
  const { sale } = useAuth();

  const clientCount = useClientCount();
  const entityCount = useEntityCount();
  const dealsStats = useDealsStats();
  const recentDeals = useRecentDeals();
  const upcomingTasks = useUpcomingTasks();

  const statsLoading =
    clientCount.isLoading || entityCount.isLoading || dealsStats.isLoading;

  // Derive display name from sale profile (full_name or first_name)
  const displayName = sale?.full_name
    ? sale.full_name.split(" ")[0]
    : sale?.first_name || "there";

  return (
    <div
      className="min-h-screen pb-24"
      style={{ background: "var(--bg-primary)" }}
    >
      {/* ---- Header / Greeting ---- */}
      <div className="px-4 pt-6 pb-2">
        <h1
          className="text-2xl font-bold font-serif"
          style={{ color: "var(--text-primary)" }}
        >
          {getGreeting()},{" "}
          <span style={{ color: "var(--text-gold)" }}>
            {displayName}
          </span>
        </h1>
        <p
          className="text-sm mt-1"
          style={{ color: "var(--text-muted)" }}
        >
          {formatToday()}
        </p>
      </div>

      {/* ---- Stats Grid ---- */}
      {statsLoading ? (
        <StatsSkeleton />
      ) : (
        <div className="grid grid-cols-2 gap-3 px-4 mt-3">
          <StatCard
            icon={
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                <path d="M16 3.13a4 4 0 0 1 0 7.75" />
              </svg>
            }
            value={String(clientCount.data ?? 0)}
            label="Total Clients"
            loading={clientCount.isLoading}
          />

          <StatCard
            icon={
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                <polyline points="9 22 9 12 15 12 15 22" />
              </svg>
            }
            value={String(entityCount.data ?? 0)}
            label="Entities"
            loading={entityCount.isLoading}
          />

          <StatCard
            icon={
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
              </svg>
            }
            value={String(dealsStats.data?.activeCount ?? 0)}
            label="Active Deals"
            loading={dealsStats.isLoading}
          />

          <StatCard
            icon={
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
              </svg>
            }
            value={formatCurrency(dealsStats.data?.pipelineValue ?? 0)}
            label="Pipeline Value"
            loading={dealsStats.isLoading}
          />
        </div>
      )}

      {/* ---- Recent Deals ---- */}
      <div className="mt-6">
        <SectionTitle count={recentDeals.data?.length}>
          Recent Deals
        </SectionTitle>

        <MobileCard noPadding className="mx-4 overflow-hidden">
          {recentDeals.isLoading ? (
            <DealsSkeleton />
          ) : recentDeals.data && recentDeals.data.length > 0 ? (
            recentDeals.data.map((deal) => (
              <RecentDealRow key={deal.id} deal={deal} />
            ))
          ) : (
            <div className="px-4 py-8 text-center">
              <p
                className="text-sm"
                style={{ color: "var(--text-muted)" }}
              >
                No deals yet
              </p>
            </div>
          )}
        </MobileCard>
      </div>

      {/* ---- Upcoming Tasks ---- */}
      <div className="mt-6">
        <SectionTitle count={upcomingTasks.data?.length}>
          Upcoming Tasks
        </SectionTitle>

        <MobileCard noPadding className="mx-4 overflow-hidden">
          {upcomingTasks.isLoading ? (
            <TasksSkeleton />
          ) : upcomingTasks.data && upcomingTasks.data.length > 0 ? (
            upcomingTasks.data.map((task) => (
              <TaskRow key={task.id} task={task} />
            ))
          ) : (
            <div className="px-4 py-8 text-center">
              <p
                className="text-sm"
                style={{ color: "var(--text-muted)" }}
              >
                All caught up — no pending tasks
              </p>
            </div>
          )}
        </MobileCard>
      </div>
    </div>
  );
}
