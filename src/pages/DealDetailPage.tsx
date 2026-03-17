import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  AlertTriangle,
  Calendar,
  ChevronRight,
  Clock,
  DollarSign,
  FileText,
  Lock,
  Plus,
  Send,
  User,
} from "lucide-react";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { formatCurrency, formatDate } from "../lib/utils";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Badge } from "../components/ui/Badge";
import { Skeleton } from "../components/ui/Skeleton";
import type { Deal, Client, ConsultantNote, Task } from "../types";

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

function priorityVariant(p?: string | null): StageBadgeVariant {
  switch (p) {
    case "critical":
      return "danger";
    case "high":
      return "warning";
    case "medium":
      return "info";
    case "low":
      return "default";
    default:
      return "default";
  }
}

function riskVariant(r?: string | null): StageBadgeVariant {
  switch (r) {
    case "high":
      return "danger";
    case "medium":
      return "warning";
    case "low":
      return "success";
    default:
      return "default";
  }
}

// ---------------------------------------------------------------------------
// Data fetchers
// ---------------------------------------------------------------------------

function useDeal(id: string | undefined) {
  return useQuery<Deal>({
    queryKey: ["deals", "detail", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("deals")
        .select("*")
        .eq("id", id!)
        .single();
      if (error) throw error;
      return data as Deal;
    },
    enabled: !!id,
  });
}

function useClientForDeal(clientId: string | null | undefined) {
  return useQuery<Client>({
    queryKey: ["clients", "one", clientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("clients")
        .select("*")
        .eq("id", clientId!)
        .single();
      if (error) throw error;
      return data as Client;
    },
    enabled: !!clientId,
  });
}

function useDealNotes(dealId: string | undefined) {
  return useQuery<ConsultantNote[]>({
    queryKey: ["consultant_notes", "deal", dealId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("consultant_notes")
        .select("*")
        .eq("deal_id", dealId!)
        .order("created_at", { ascending: false });
      if (error) {
        // Table may not exist yet — return empty array gracefully
        console.warn("consultant_notes query error:", error.message);
        return [];
      }
      return (data ?? []) as ConsultantNote[];
    },
    enabled: !!dealId,
  });
}

function useDealTasks(dealId: string | undefined) {
  return useQuery<Task[]>({
    queryKey: ["tasks", "deal", dealId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("tasks")
        .select("*")
        .eq("deal_id", dealId!)
        .order("created_at", { ascending: false });
      if (error) {
        console.warn("tasks query error:", error.message);
        return [];
      }
      return (data ?? []) as Task[];
    },
    enabled: !!dealId,
  });
}

// ---------------------------------------------------------------------------
// Skeletons
// ---------------------------------------------------------------------------

function HeroSkeleton() {
  return (
    <MobileCard className="mx-4 space-y-4">
      <Skeleton className="h-7 w-48" />
      <Skeleton className="h-10 w-32" />
      <div className="flex gap-2">
        <Skeleton className="h-5 w-24 rounded-full" />
        <Skeleton className="h-5 w-20 rounded-full" />
      </div>
      <div className="space-y-2 pt-2">
        <Skeleton className="h-4 w-40" />
        <Skeleton className="h-4 w-36" />
        <Skeleton className="h-4 w-36" />
      </div>
    </MobileCard>
  );
}

function SectionSkeleton() {
  return (
    <MobileCard className="mx-4">
      <div className="flex items-center gap-3">
        <Skeleton className="w-10 h-10 rounded-full" />
        <div className="flex-1 space-y-2">
          <Skeleton className="h-4 w-32" />
          <Skeleton className="h-3 w-24" />
        </div>
      </div>
    </MobileCard>
  );
}

function NotesSkeleton() {
  return (
    <div className="mx-4 space-y-3">
      {Array.from({ length: 2 }).map((_, i) => (
        <MobileCard key={i} className="space-y-2">
          <div className="flex items-center gap-2">
            <Skeleton className="h-3 w-20" />
            <Skeleton className="h-3 w-24" />
          </div>
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-3/4" />
        </MobileCard>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Inline Add Note Form
// ---------------------------------------------------------------------------

function AddNoteForm({ dealId }: { dealId: string }) {
  const [text, setText] = useState("");
  const [open, setOpen] = useState(false);
  const { user } = useAuth();
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: async (noteText: string) => {
      const { error } = await supabase.from("consultant_notes").insert({
        deal_id: dealId,
        text: noteText,
        date: new Date().toISOString(),
        created_by: user?.id ?? null,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      setText("");
      setOpen(false);
      queryClient.invalidateQueries({ queryKey: ["consultant_notes", "deal", dealId] });
    },
  });

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        className="flex items-center gap-2 w-full px-4 py-3 rounded-2xl text-sm font-semibold transition-all active:scale-[0.98]"
        style={{
          background: "color-mix(in srgb, var(--gold) 12%, transparent)",
          color: "var(--text-gold)",
        }}
      >
        <Plus size={16} />
        Add Note
      </button>
    );
  }

  return (
    <MobileCard className="space-y-3">
      <textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="Write a note..."
        rows={3}
        autoFocus
        className="w-full rounded-xl px-3 py-2.5 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-[var(--gold)]"
        style={{
          background: "var(--bg-primary)",
          color: "var(--text-primary)",
          border: "1px solid var(--border-light)",
        }}
      />
      <div className="flex items-center justify-end gap-2">
        <button
          onClick={() => {
            setOpen(false);
            setText("");
          }}
          className="px-4 py-2 rounded-xl text-sm font-medium transition-colors active:opacity-70"
          style={{ color: "var(--text-secondary)" }}
        >
          Cancel
        </button>
        <button
          onClick={() => {
            if (text.trim()) mutation.mutate(text.trim());
          }}
          disabled={!text.trim() || mutation.isPending}
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl text-sm font-semibold text-white transition-all active:scale-[0.97] disabled:opacity-40"
          style={{ background: "var(--gold)" }}
        >
          {mutation.isPending ? (
            <div
              className="w-4 h-4 rounded-full border-2 border-t-transparent animate-spin"
              style={{ borderColor: "white", borderTopColor: "transparent" }}
            />
          ) : (
            <Send size={14} />
          )}
          Save
        </button>
      </div>
      {mutation.isError && (
        <p className="text-xs" style={{ color: "var(--danger)" }}>
          Failed to save note. Please try again.
        </p>
      )}
    </MobileCard>
  );
}

// ---------------------------------------------------------------------------
// Info Row helper
// ---------------------------------------------------------------------------

function InfoRow({
  icon: Icon,
  label,
  value,
}: {
  icon: React.ComponentType<{ size: number; style?: React.CSSProperties }>;
  label: string;
  value: string | null | undefined;
}) {
  if (!value) return null;
  return (
    <div className="flex items-start gap-2.5">
      <Icon size={14} style={{ color: "var(--text-muted)", flexShrink: 0, marginTop: 2 }} />
      <div>
        <span className="text-[11px] font-medium" style={{ color: "var(--text-muted)" }}>
          {label}
        </span>
        <p className="text-xs font-medium" style={{ color: "var(--text-primary)" }}>
          {value}
        </p>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main Page
// ---------------------------------------------------------------------------

export function DealDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const { data: deal, isLoading, isError } = useDeal(id);
  const { data: client, isLoading: clientLoading } = useClientForDeal(deal?.client_id);
  const { data: notes, isLoading: notesLoading } = useDealNotes(id);
  const { data: tasks, isLoading: tasksLoading } = useDealTasks(id);

  // ---- Error state ----
  if (isError) {
    return (
      <div className="min-h-screen" style={{ background: "var(--bg-primary)" }}>
        <PageHeader title="Deal" back />
        <div className="flex flex-col items-center justify-center px-6 pt-20 text-center">
          <div
            className="w-14 h-14 rounded-full flex items-center justify-center mb-4"
            style={{
              background: "color-mix(in srgb, var(--danger) 12%, transparent)",
              color: "var(--danger)",
            }}
          >
            <FileText size={24} />
          </div>
          <p className="text-base font-semibold" style={{ color: "var(--text-primary)" }}>
            Deal not found
          </p>
          <p className="text-sm mt-1" style={{ color: "var(--text-muted)" }}>
            This deal may have been deleted or you may not have access.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen pb-24" style={{ background: "var(--bg-primary)" }}>
      {/* ---- Header ---- */}
      <PageHeader title={deal?.name ?? "Deal"} back />

      {/* ---- Hero Card ---- */}
      {isLoading ? (
        <HeroSkeleton />
      ) : deal ? (
        <MobileCard className="mx-4">
          {/* Confidential badge */}
          {deal.is_confidential && (
            <div className="flex items-center gap-1.5 mb-2">
              <Lock size={12} style={{ color: "var(--danger)" }} />
              <span className="text-[10px] font-bold uppercase tracking-wider" style={{ color: "var(--danger)" }}>
                Confidential
              </span>
            </div>
          )}

          {/* Deal name */}
          <h2
            className="text-xl font-bold font-serif leading-tight"
            style={{ color: "var(--text-primary)" }}
          >
            {deal.name}
          </h2>

          {/* Deal value */}
          {deal.deal_value != null && deal.deal_value > 0 && (
            <p
              className="text-3xl font-bold font-serif tracking-tight mt-2"
              style={{ color: "var(--text-gold)" }}
            >
              {formatCurrency(deal.deal_value)}
            </p>
          )}

          {/* Badges */}
          <div className="flex flex-wrap items-center gap-2 mt-3">
            <Badge variant={stageBadgeVariant(deal.stage)}>
              {stageLabel(deal.stage)}
            </Badge>
            {deal.status && (
              <Badge variant="outline">{deal.status}</Badge>
            )}
            {deal.deal_type && (
              <Badge variant="outline">{deal.deal_type}</Badge>
            )}
            {deal.priority && (
              <Badge variant={priorityVariant(deal.priority)}>
                {deal.priority}
              </Badge>
            )}
            {deal.risk_level && (
              <Badge variant={riskVariant(deal.risk_level)}>
                Risk: {deal.risk_level}
              </Badge>
            )}
          </div>

          {/* Meta dates */}
          <div className="mt-4 space-y-2.5">
            <InfoRow icon={Calendar} label="Expected Close" value={deal.expected_close_date ? formatDate(deal.expected_close_date) : null} />
            <InfoRow icon={Calendar} label="Actual Close" value={deal.actual_close_date ? formatDate(deal.actual_close_date) : null} />
            <InfoRow icon={Calendar} label="DD Start" value={deal.dd_start_date ? formatDate(deal.dd_start_date) : null} />
            <InfoRow icon={Calendar} label="DD End" value={deal.dd_end_date ? formatDate(deal.dd_end_date) : null} />
            <InfoRow icon={Calendar} label="LOI Signed" value={deal.loi_signed_date ? formatDate(deal.loi_signed_date) : null} />
            <div className="flex items-center gap-2">
              <Clock size={14} style={{ color: "var(--text-muted)", flexShrink: 0 }} />
              <span className="text-xs" style={{ color: "var(--text-muted)" }}>
                Created {formatDate(deal.created_at)}
                {deal.updated_at &&
                  deal.updated_at !== deal.created_at &&
                  ` -- Updated ${formatDate(deal.updated_at)}`}
              </span>
            </div>
          </div>
        </MobileCard>
      ) : null}

      {/* ---- Financials Section ---- */}
      {deal && (deal.enterprise_value || deal.equity_value || deal.expected_revenue) && (
        <div className="mt-5">
          <SectionTitle>Financials</SectionTitle>
          <MobileCard className="mx-4 space-y-3">
            {deal.enterprise_value != null && deal.enterprise_value > 0 && (
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium" style={{ color: "var(--text-muted)" }}>
                  Enterprise Value
                </span>
                <span className="text-sm font-bold" style={{ color: "var(--text-primary)" }}>
                  {formatCurrency(deal.enterprise_value)}
                </span>
              </div>
            )}
            {deal.equity_value != null && deal.equity_value > 0 && (
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium" style={{ color: "var(--text-muted)" }}>
                  Equity Value
                </span>
                <span className="text-sm font-bold" style={{ color: "var(--text-primary)" }}>
                  {formatCurrency(deal.equity_value)}
                </span>
              </div>
            )}
            {deal.expected_revenue != null && deal.expected_revenue > 0 && (
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium" style={{ color: "var(--text-muted)" }}>
                  Expected Revenue
                </span>
                <span className="text-sm font-bold" style={{ color: "var(--text-gold)" }}>
                  {formatCurrency(deal.expected_revenue)}
                </span>
              </div>
            )}
          </MobileCard>
        </div>
      )}

      {/* ---- Client Section ---- */}
      {deal?.client_id && (
        <div className="mt-5">
          <SectionTitle>Client</SectionTitle>
          {clientLoading ? (
            <SectionSkeleton />
          ) : client ? (
            <MobileCard className="mx-4">
              <button
                onClick={() => navigate(`/contacts/${client.id}`)}
                className="flex items-center gap-3 w-full text-left transition-colors active:opacity-80"
              >
                <div
                  className="w-10 h-10 rounded-full flex items-center justify-center shrink-0"
                  style={{
                    background: "color-mix(in srgb, var(--gold) 12%, transparent)",
                    color: "var(--text-gold)",
                  }}
                >
                  <User size={18} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold truncate" style={{ color: "var(--text-primary)" }}>
                    {client.name}
                  </p>
                  {client.industry && (
                    <p className="text-xs truncate mt-0.5" style={{ color: "var(--text-secondary)" }}>
                      {client.industry}
                    </p>
                  )}
                </div>
                <ChevronRight size={18} style={{ color: "var(--text-muted)", flexShrink: 0 }} />
              </button>
            </MobileCard>
          ) : null}
        </div>
      )}

      {/* ---- Deal Parties ---- */}
      {deal && (deal.target_company || deal.buyer_name || deal.seller_name) && (
        <div className="mt-5">
          <SectionTitle>Parties</SectionTitle>
          <MobileCard className="mx-4 space-y-2.5">
            <InfoRow icon={User} label="Target Company" value={deal.target_company} />
            <InfoRow icon={User} label="Buyer" value={deal.buyer_name} />
            <InfoRow icon={User} label="Seller" value={deal.seller_name} />
          </MobileCard>
        </div>
      )}

      {/* ---- Description Section ---- */}
      {deal?.description && (
        <div className="mt-5">
          <SectionTitle>Description</SectionTitle>
          <MobileCard className="mx-4">
            <p
              className="text-sm leading-relaxed whitespace-pre-wrap"
              style={{ color: "var(--text-secondary)" }}
            >
              {deal.description}
            </p>
          </MobileCard>
        </div>
      )}

      {/* ---- Strategic Rationale ---- */}
      {deal?.strategic_rationale && (
        <div className="mt-5">
          <SectionTitle>Strategic Rationale</SectionTitle>
          <MobileCard className="mx-4">
            <p
              className="text-sm leading-relaxed whitespace-pre-wrap"
              style={{ color: "var(--text-secondary)" }}
            >
              {deal.strategic_rationale}
            </p>
          </MobileCard>
        </div>
      )}

      {/* ---- Synergies ---- */}
      {deal?.synergies_description && (
        <div className="mt-5">
          <SectionTitle>Synergies</SectionTitle>
          <MobileCard className="mx-4">
            <p
              className="text-sm leading-relaxed whitespace-pre-wrap"
              style={{ color: "var(--text-secondary)" }}
            >
              {deal.synergies_description}
            </p>
          </MobileCard>
        </div>
      )}

      {/* ---- Payment Structure ---- */}
      {deal?.payment_structure && (
        <div className="mt-5">
          <SectionTitle>Payment Structure</SectionTitle>
          <MobileCard className="mx-4">
            <p
              className="text-sm leading-relaxed whitespace-pre-wrap"
              style={{ color: "var(--text-secondary)" }}
            >
              {deal.payment_structure}
            </p>
          </MobileCard>
        </div>
      )}

      {/* ---- Tasks Section ---- */}
      <div className="mt-5">
        <SectionTitle count={tasks?.length}>Tasks</SectionTitle>
        {tasksLoading ? (
          <NotesSkeleton />
        ) : tasks && tasks.length > 0 ? (
          <div className="mx-4 space-y-2">
            {tasks.map((task) => (
              <MobileCard key={task.id}>
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold truncate" style={{ color: "var(--text-primary)" }}>
                      {task.title}
                    </p>
                    {task.description && (
                      <p className="text-xs mt-1 line-clamp-2" style={{ color: "var(--text-muted)" }}>
                        {task.description}
                      </p>
                    )}
                  </div>
                  <div className="flex items-center gap-1.5 flex-shrink-0">
                    {task.status && (
                      <Badge variant={task.status === "completed" ? "success" : task.status === "in_progress" ? "warning" : "default"}>
                        {task.status}
                      </Badge>
                    )}
                  </div>
                </div>
                {task.due_date && (
                  <p className="text-[11px] mt-1.5" style={{ color: "var(--text-muted)" }}>
                    Due: {formatDate(task.due_date)}
                  </p>
                )}
              </MobileCard>
            ))}
          </div>
        ) : (
          <div className="mx-4 py-6 text-center">
            <p className="text-sm" style={{ color: "var(--text-muted)" }}>
              No tasks yet
            </p>
          </div>
        )}
      </div>

      {/* ---- Notes Section ---- */}
      <div className="mt-5">
        <SectionTitle count={notes?.length}>Notes</SectionTitle>

        {notesLoading ? (
          <NotesSkeleton />
        ) : (
          <div className="mx-4 space-y-3">
            {/* Add note form */}
            {id && <AddNoteForm dealId={id} />}

            {/* Notes list */}
            {notes && notes.length > 0 ? (
              notes.map((note) => (
                <MobileCard key={note.id}>
                  {/* Note header: date */}
                  <div className="flex items-center gap-2 mb-2">
                    <span
                      className="text-[11px] font-medium"
                      style={{ color: "var(--text-muted)" }}
                    >
                      {formatDate(note.date || note.created_at)}
                    </span>
                  </div>

                  {/* Note body */}
                  <p
                    className="text-sm leading-relaxed whitespace-pre-wrap"
                    style={{ color: "var(--text-primary)" }}
                  >
                    {note.text}
                  </p>
                </MobileCard>
              ))
            ) : (
              <div className="py-6 text-center">
                <p className="text-sm" style={{ color: "var(--text-muted)" }}>
                  No notes yet
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
