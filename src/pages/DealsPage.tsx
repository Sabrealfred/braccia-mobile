import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Handshake, LayoutList, Columns3 } from "lucide-react";
import { supabase } from "../lib/supabase";
import { formatCurrency, formatRelativeDate } from "../lib/utils";
import { SearchBar } from "../components/ui/SearchBar";
import { FAB } from "../components/ui/FAB";
import { Badge } from "../components/ui/Badge";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { PageHeader } from "../components/ui/PageHeader";
import type { Deal } from "../types";

// ---------------------------------------------------------------------------
// Stage configuration
// ---------------------------------------------------------------------------

interface StageConfig {
  label: string;
  variant: "info" | "warning" | "gold" | "success" | "danger" | "default";
  color: string;
}

const STAGES: Record<string, StageConfig> = {
  opportunity: { label: "Opportunity", variant: "info", color: "var(--info)" },
  "proposal-sent": { label: "Proposal Sent", variant: "warning", color: "var(--warning)" },
  "in-negotiation": { label: "In Negotiation", variant: "gold", color: "var(--gold)" },
  won: { label: "Won", variant: "success", color: "var(--success)" },
  lost: { label: "Lost", variant: "danger", color: "var(--danger)" },
  cancelled: { label: "Cancelled", variant: "default", color: "var(--text-muted)" },
};

const STAGE_ORDER = ["opportunity", "proposal-sent", "in-negotiation", "won", "lost", "cancelled"];

type DealWithCompany = Deal & { companies: { name: string } | null };

// ---------------------------------------------------------------------------
// Data hook
// ---------------------------------------------------------------------------

function useDeals(search: string) {
  return useQuery({
    queryKey: ["deals", search],
    queryFn: async () => {
      let query = supabase
        .from("deals")
        .select("*, companies(name)")
        .order("index");

      if (search.trim()) {
        query = query.ilike("name", `%${search.trim()}%`);
      }

      const { data, error } = await query;
      if (error) throw error;
      return (data ?? []) as DealWithCompany[];
    },
  });
}

// ---------------------------------------------------------------------------
// View toggle
// ---------------------------------------------------------------------------

type ViewMode = "list" | "kanban";

function ViewToggle({ mode, onChange }: { mode: ViewMode; onChange: (m: ViewMode) => void }) {
  return (
    <div
      className="flex rounded-lg overflow-hidden"
      style={{ border: "1px solid var(--border-light)" }}
    >
      <button
        onClick={() => onChange("list")}
        className="flex items-center justify-center w-9 h-9 transition-colors"
        style={{
          background: mode === "list" ? "var(--gold)" : "transparent",
          color: mode === "list" ? "var(--white)" : "var(--text-muted)",
        }}
        aria-label="List view"
      >
        <LayoutList size={16} />
      </button>
      <button
        onClick={() => onChange("kanban")}
        className="flex items-center justify-center w-9 h-9 transition-colors"
        style={{
          background: mode === "kanban" ? "var(--gold)" : "transparent",
          color: mode === "kanban" ? "var(--white)" : "var(--text-muted)",
          borderLeft: "1px solid var(--border-light)",
        }}
        aria-label="Kanban view"
      >
        <Columns3 size={16} />
      </button>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Kanban card
// ---------------------------------------------------------------------------

function KanbanCard({ deal, onClick }: { deal: DealWithCompany; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="w-full text-left rounded-xl p-3 mb-2 active:scale-[0.98] transition-transform"
      style={{
        background: "var(--bg-card)",
        border: "1px solid var(--border-light)",
      }}
    >
      <p
        className="text-sm font-semibold truncate"
        style={{ color: "var(--text-primary)" }}
      >
        {deal.name}
      </p>
      {deal.companies?.name && (
        <p
          className="text-xs truncate mt-0.5"
          style={{ color: "var(--text-muted)" }}
        >
          {deal.companies.name}
        </p>
      )}
      <div className="flex items-center justify-between mt-2">
        <span
          className="text-xs font-bold"
          style={{ color: "var(--text-gold)" }}
        >
          {formatCurrency(deal.amount ?? 0)}
        </span>
        <span className="text-[10px]" style={{ color: "var(--text-muted)" }}>
          {formatRelativeDate(deal.updated_at)}
        </span>
      </div>
    </button>
  );
}

// ---------------------------------------------------------------------------
// Kanban view
// ---------------------------------------------------------------------------

function KanbanView({ deals, navigate }: { deals: DealWithCompany[]; navigate: ReturnType<typeof useNavigate> }) {
  const grouped = useMemo(() => {
    const map: Record<string, DealWithCompany[]> = {};
    for (const stage of STAGE_ORDER) {
      map[stage] = [];
    }
    for (const deal of deals) {
      const key = deal.stage ?? "opportunity";
      if (!map[key]) map[key] = [];
      map[key].push(deal);
    }
    return map;
  }, [deals]);

  return (
    <div
      className="flex gap-3 overflow-x-auto pb-32 px-4 pt-2"
      style={{ minHeight: "calc(100dvh - 120px)" }}
    >
      {STAGE_ORDER.map((stage) => {
        const cfg = STAGES[stage] ?? STAGES.opportunity;
        const items = grouped[stage] ?? [];
        const total = items.reduce((sum, d) => sum + (d.amount ?? 0), 0);

        return (
          <div
            key={stage}
            className="kanban-col flex-shrink-0 flex flex-col"
            style={{ minWidth: 280, maxWidth: 320, width: 280 }}
          >
            {/* Column header */}
            <div
              className="rounded-xl px-3 py-2.5 mb-2"
              style={{ background: "var(--bg-secondary)" }}
            >
              <div className="flex items-center gap-2">
                <span
                  className="w-2.5 h-2.5 rounded-full flex-shrink-0"
                  style={{ background: cfg.color }}
                />
                <span
                  className="text-xs font-semibold uppercase tracking-wider flex-1 truncate"
                  style={{ color: "var(--text-primary)" }}
                >
                  {cfg.label}
                </span>
                <span
                  className="text-[10px] font-medium px-1.5 py-0.5 rounded-full"
                  style={{
                    background: "var(--bg-muted)",
                    color: "var(--text-secondary)",
                  }}
                >
                  {items.length}
                </span>
              </div>
              {total > 0 && (
                <p
                  className="text-[11px] font-semibold mt-1 pl-[18px]"
                  style={{ color: "var(--text-gold)" }}
                >
                  {formatCurrency(total)}
                </p>
              )}
            </div>

            {/* Cards */}
            <div className="flex-1 overflow-y-auto space-y-0">
              {items.map((deal) => (
                <KanbanCard
                  key={deal.id}
                  deal={deal}
                  onClick={() => navigate(`/deals/${deal.id}`)}
                />
              ))}
              {items.length === 0 && (
                <p
                  className="text-[11px] text-center py-6"
                  style={{ color: "var(--text-muted)", opacity: 0.5 }}
                >
                  No deals
                </p>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ---------------------------------------------------------------------------
// List view
// ---------------------------------------------------------------------------

function ListView({
  deals,
  search,
  onSearchChange,
  navigate,
}: {
  deals: DealWithCompany[];
  search: string;
  onSearchChange: (v: string) => void;
  navigate: ReturnType<typeof useNavigate>;
}) {
  const grouped = useMemo(() => {
    const map: Record<string, DealWithCompany[]> = {};
    for (const stage of STAGE_ORDER) {
      map[stage] = [];
    }
    for (const deal of deals) {
      const key = deal.stage ?? "opportunity";
      if (!map[key]) map[key] = [];
      map[key].push(deal);
    }
    return map;
  }, [deals]);

  return (
    <>
      <SearchBar
        value={search}
        onChange={onSearchChange}
        placeholder="Search deals..."
      />

      <div className="pb-32">
        {STAGE_ORDER.map((stage) => {
          const items = grouped[stage] ?? [];
          if (items.length === 0) return null;

          const cfg = STAGES[stage] ?? STAGES.opportunity;

          return (
            <div key={stage}>
              <SectionTitle count={items.length}>{cfg.label}</SectionTitle>

              {items.map((deal) => (
                <MobileCard
                  key={deal.id}
                  className="mx-4 mb-2 active:scale-[0.98] transition-transform cursor-pointer"
                  onClick={() => navigate(`/deals/${deal.id}`)}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex-1 min-w-0">
                      <p
                        className="text-sm font-semibold truncate"
                        style={{ color: "var(--text-primary)" }}
                      >
                        {deal.name}
                      </p>
                      {deal.companies?.name && (
                        <p
                          className="text-xs truncate mt-0.5"
                          style={{ color: "var(--text-muted)" }}
                        >
                          {deal.companies.name}
                        </p>
                      )}
                    </div>
                    <Badge variant="gold">{formatCurrency(deal.amount ?? 0)}</Badge>
                  </div>

                  <div className="flex items-center gap-2 mt-2">
                    <Badge variant={cfg.variant}>{cfg.label}</Badge>
                    <span
                      className="text-[10px] ml-auto"
                      style={{ color: "var(--text-muted)" }}
                    >
                      {formatRelativeDate(deal.updated_at)}
                    </span>
                  </div>
                </MobileCard>
              ))}
            </div>
          );
        })}
      </div>
    </>
  );
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------

export function DealsPage() {
  const navigate = useNavigate();
  const [viewMode, setViewMode] = useState<ViewMode>("list");
  const [search, setSearch] = useState("");

  const { data: deals, isLoading, isError } = useDeals(
    viewMode === "list" ? search : ""
  );

  const isEmpty = !isLoading && !isError && deals?.length === 0;

  return (
    <div style={{ background: "var(--bg-primary)", minHeight: "100dvh" }}>
      <PageHeader
        title="Deals"
        actions={<ViewToggle mode={viewMode} onChange={setViewMode} />}
      />

      {/* Loading */}
      {isLoading && <ListSkeleton count={6} />}

      {/* Error */}
      {isError && (
        <EmptyState
          icon={Handshake}
          title="Failed to load deals"
          description="Check your connection and try again."
        />
      )}

      {/* Empty */}
      {isEmpty && (
        <EmptyState
          icon={Handshake}
          title="No deals yet"
          description="Create your first deal to start tracking opportunities."
        />
      )}

      {/* Content */}
      {!isLoading && !isError && deals && deals.length > 0 && (
        viewMode === "kanban" ? (
          <KanbanView deals={deals} navigate={navigate} />
        ) : (
          <ListView
            deals={deals}
            search={search}
            onSearchChange={setSearch}
            navigate={navigate}
          />
        )
      )}

      <FAB to="/deals/create" label="New Deal" />
    </div>
  );
}
