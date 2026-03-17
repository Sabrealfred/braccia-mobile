import { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Building2,
  Calendar,
  ChevronRight,
  Clock,
  FileText,
  Plus,
  Send,
  User,
} from "lucide-react";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { formatCurrency, formatDate } from "../lib/utils";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Avatar } from "../components/ui/Avatar";
import { Badge } from "../components/ui/Badge";
import { Skeleton } from "../components/ui/Skeleton";
import type { Deal, DealNote, Contact, Company } from "../types";

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

function useCompanyForDeal(companyId: number | undefined) {
  return useQuery<Company>({
    queryKey: ["companies", "one", companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("companies")
        .select("*")
        .eq("id", companyId!)
        .single();
      if (error) throw error;
      return data as Company;
    },
    enabled: !!companyId,
  });
}

function useContactsForDeal(contactIds: number[] | undefined) {
  return useQuery<Contact[]>({
    queryKey: ["contacts", "forDeal", contactIds],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("contacts")
        .select("*")
        .in("id", contactIds!);
      if (error) throw error;
      return data as Contact[];
    },
    enabled: !!contactIds && contactIds.length > 0,
  });
}

type DealNoteWithAuthor = DealNote & {
  sales: { first_name: string; last_name: string } | null;
};

function useDealNotes(dealId: string | undefined) {
  return useQuery<DealNoteWithAuthor[]>({
    queryKey: ["dealNotes", "list", dealId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("dealNotes")
        .select("*, sales(first_name, last_name)")
        .eq("deal_id", dealId!)
        .order("date", { ascending: false });
      if (error) throw error;
      return (data ?? []) as DealNoteWithAuthor[];
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
  const { sale } = useAuth();
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: async (noteText: string) => {
      const { error } = await supabase.from("dealNotes").insert({
        deal_id: Number(dealId),
        text: noteText,
        date: new Date().toISOString(),
        sales_id: sale?.id,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      setText("");
      setOpen(false);
      queryClient.invalidateQueries({ queryKey: ["dealNotes", "list", dealId] });
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
// Main Page
// ---------------------------------------------------------------------------

export function DealDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const { data: deal, isLoading, isError } = useDeal(id);
  const { data: company, isLoading: companyLoading } = useCompanyForDeal(
    deal?.company_id
  );
  const { data: contacts, isLoading: contactsLoading } = useContactsForDeal(
    deal?.contact_ids
  );
  const { data: notes, isLoading: notesLoading } = useDealNotes(id);

  // ---- Error state ----
  if (isError) {
    return (
      <div
        className="min-h-screen"
        style={{ background: "var(--bg-primary)" }}
      >
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
          <p
            className="text-base font-semibold"
            style={{ color: "var(--text-primary)" }}
          >
            Deal not found
          </p>
          <p
            className="text-sm mt-1"
            style={{ color: "var(--text-muted)" }}
          >
            This deal may have been deleted or you may not have access.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div
      className="min-h-screen pb-24"
      style={{ background: "var(--bg-primary)" }}
    >
      {/* ---- Header ---- */}
      <PageHeader title={deal?.name ?? "Deal"} back />

      {/* ---- Hero Card ---- */}
      {isLoading ? (
        <HeroSkeleton />
      ) : deal ? (
        <MobileCard className="mx-4">
          {/* Deal name */}
          <h2
            className="text-xl font-bold font-serif leading-tight"
            style={{ color: "var(--text-primary)" }}
          >
            {deal.name}
          </h2>

          {/* Amount */}
          <p
            className="text-3xl font-bold font-serif tracking-tight mt-2"
            style={{ color: "var(--text-gold)" }}
          >
            {formatCurrency(deal.amount)}
          </p>

          {/* Badges */}
          <div className="flex flex-wrap items-center gap-2 mt-3">
            <Badge variant={stageBadgeVariant(deal.stage)}>
              {stageLabel(deal.stage)}
            </Badge>
            {deal.category && (
              <Badge variant="outline">{deal.category}</Badge>
            )}
          </div>

          {/* Meta dates */}
          <div className="mt-4 space-y-2">
            {deal.expected_closing_date && (
              <div className="flex items-center gap-2">
                <Calendar
                  size={14}
                  style={{ color: "var(--text-muted)", flexShrink: 0 }}
                />
                <span
                  className="text-xs font-medium"
                  style={{ color: "var(--text-secondary)" }}
                >
                  Expected close:{" "}
                  <span style={{ color: "var(--text-primary)" }}>
                    {formatDate(deal.expected_closing_date)}
                  </span>
                </span>
              </div>
            )}
            <div className="flex items-center gap-2">
              <Clock
                size={14}
                style={{ color: "var(--text-muted)", flexShrink: 0 }}
              />
              <span
                className="text-xs"
                style={{ color: "var(--text-muted)" }}
              >
                Created {formatDate(deal.created_at)}
                {deal.updated_at &&
                  deal.updated_at !== deal.created_at &&
                  ` · Updated ${formatDate(deal.updated_at)}`}
              </span>
            </div>
          </div>
        </MobileCard>
      ) : null}

      {/* ---- Company Section ---- */}
      {deal?.company_id && (
        <div className="mt-5">
          <SectionTitle>Company</SectionTitle>
          {companyLoading ? (
            <SectionSkeleton />
          ) : company ? (
            <MobileCard className="mx-4">
              <button
                onClick={() => navigate(`/companies/${company.id}`)}
                className="flex items-center gap-3 w-full text-left transition-colors active:opacity-80"
              >
                <div
                  className="w-10 h-10 rounded-full flex items-center justify-center shrink-0"
                  style={{
                    background:
                      "color-mix(in srgb, var(--gold) 12%, transparent)",
                    color: "var(--text-gold)",
                  }}
                >
                  <Building2 size={18} />
                </div>
                <div className="flex-1 min-w-0">
                  <p
                    className="text-sm font-semibold truncate"
                    style={{ color: "var(--text-primary)" }}
                  >
                    {company.name}
                  </p>
                  {company.sector && (
                    <p
                      className="text-xs truncate mt-0.5"
                      style={{ color: "var(--text-secondary)" }}
                    >
                      {company.sector}
                    </p>
                  )}
                </div>
                <ChevronRight
                  size={18}
                  style={{ color: "var(--text-muted)", flexShrink: 0 }}
                />
              </button>
            </MobileCard>
          ) : null}
        </div>
      )}

      {/* ---- Contacts Section ---- */}
      {deal?.contact_ids && deal.contact_ids.length > 0 && (
        <div className="mt-5">
          <SectionTitle count={contacts?.length ?? deal.contact_ids.length}>
            Contacts
          </SectionTitle>
          {contactsLoading ? (
            <div className="mx-4 space-y-2">
              {Array.from({ length: Math.min(deal.contact_ids.length, 3) }).map(
                (_, i) => (
                  <SectionSkeleton key={i} />
                )
              )}
            </div>
          ) : contacts && contacts.length > 0 ? (
            <MobileCard noPadding className="mx-4 overflow-hidden">
              {contacts.map((contact, idx) => (
                <button
                  key={contact.id}
                  onClick={() => navigate(`/contacts/${contact.id}`)}
                  className="flex items-center gap-3 w-full px-4 py-3 text-left transition-colors active:bg-[var(--bg-muted)]"
                  style={{
                    borderBottom:
                      idx < contacts.length - 1
                        ? "1px solid var(--border-light)"
                        : undefined,
                  }}
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
                    {contact.title && (
                      <p
                        className="text-xs truncate mt-0.5"
                        style={{ color: "var(--text-secondary)" }}
                      >
                        {contact.title}
                      </p>
                    )}
                  </div>
                  <ChevronRight
                    size={18}
                    style={{ color: "var(--text-muted)", flexShrink: 0 }}
                  />
                </button>
              ))}
            </MobileCard>
          ) : null}
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
                  {/* Note header: date + author */}
                  <div className="flex items-center gap-2 mb-2">
                    <span
                      className="text-[11px] font-medium"
                      style={{ color: "var(--text-muted)" }}
                    >
                      {formatDate(note.date)}
                    </span>
                    {note.sales && (
                      <>
                        <span
                          className="text-[11px]"
                          style={{ color: "var(--text-muted)" }}
                        >
                          &middot;
                        </span>
                        <div className="flex items-center gap-1">
                          <User
                            size={11}
                            style={{ color: "var(--text-muted)" }}
                          />
                          <span
                            className="text-[11px] font-medium"
                            style={{ color: "var(--text-secondary)" }}
                          >
                            {note.sales.first_name} {note.sales.last_name}
                          </span>
                        </div>
                      </>
                    )}
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
                <p
                  className="text-sm"
                  style={{ color: "var(--text-muted)" }}
                >
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
