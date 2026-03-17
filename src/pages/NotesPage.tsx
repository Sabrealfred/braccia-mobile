import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { StickyNote, MessageSquare, ChevronRight, User, Briefcase } from "lucide-react";
import { supabase } from "../lib/supabase";
import { formatRelativeDate } from "../lib/utils";
import { SearchBar } from "../components/ui/SearchBar";
import { Badge } from "../components/ui/Badge";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import { MobileCard } from "../components/ui/MobileCard";
import type { ContactNote, DealNote, NoteStatus } from "../types";

// ── Note status colors ──────────────────────────────────────────
const NOTE_STATUSES: NoteStatus[] = [
  { value: "cold", label: "Cold", color: "#3b82f6" },
  { value: "warm", label: "Warm", color: "#f59e0b" },
  { value: "hot", label: "Hot", color: "#ef4444" },
  { value: "in-progress", label: "In Progress", color: "#8b5cf6" },
  { value: "success", label: "Success", color: "#10b981" },
];

function getStatusColor(status: string): string | undefined {
  return NOTE_STATUSES.find(
    (s) => s.value.toLowerCase() === status.toLowerCase()
  )?.color;
}

type BadgeVariant = "danger" | "warning" | "info" | "success" | "default";

const statusVariantMap: Record<string, BadgeVariant> = {
  hot: "danger",
  warm: "warning",
  cold: "info",
  success: "success",
  "in-progress": "default",
};

function getStatusVariant(status: string): BadgeVariant {
  return statusVariantMap[status.toLowerCase()] ?? "default";
}

// ── Types with joined relations ─────────────────────────────────
interface ContactNoteWithRelations extends ContactNote {
  contacts?: { first_name: string; last_name: string } | null;
  sales?: { first_name: string; last_name: string } | null;
}

interface DealNoteWithRelations extends DealNote {
  deals?: { name: string } | null;
  sales?: { first_name: string; last_name: string } | null;
}

// ── Data fetchers ───────────────────────────────────────────────
async function fetchContactNotes(
  search: string
): Promise<ContactNoteWithRelations[]> {
  let query = supabase
    .from("contactNotes")
    .select(
      "*, contacts(first_name, last_name), sales(first_name, last_name)"
    )
    .order("date", { ascending: false });

  if (search.trim()) {
    query = query.ilike("text", `%${search.trim()}%`);
  }

  const { data, error } = await query;
  if (error) throw error;
  return (data as ContactNoteWithRelations[]) ?? [];
}

async function fetchDealNotes(
  search: string
): Promise<DealNoteWithRelations[]> {
  let query = supabase
    .from("dealNotes")
    .select("*, deals(name), sales(first_name, last_name)")
    .order("date", { ascending: false });

  if (search.trim()) {
    query = query.ilike("text", `%${search.trim()}%`);
  }

  const { data, error } = await query;
  if (error) throw error;
  return (data as DealNoteWithRelations[]) ?? [];
}

// ── Tabs ────────────────────────────────────────────────────────
type Tab = "contact" | "deal";

// ── Page Component ──────────────────────────────────────────────
export function NotesPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [activeTab, setActiveTab] = useState<Tab>("contact");

  // Contact notes query
  const {
    data: contactNotes,
    isLoading: contactLoading,
    isError: contactError,
    error: contactErr,
  } = useQuery<ContactNoteWithRelations[]>({
    queryKey: ["contactNotes", search],
    queryFn: () => fetchContactNotes(search),
    enabled: activeTab === "contact",
  });

  // Deal notes query
  const {
    data: dealNotes,
    isLoading: dealLoading,
    isError: dealError,
    error: dealErr,
  } = useQuery<DealNoteWithRelations[]>({
    queryKey: ["dealNotes", search],
    queryFn: () => fetchDealNotes(search),
    enabled: activeTab === "deal",
  });

  const isLoading = activeTab === "contact" ? contactLoading : dealLoading;
  const isError = activeTab === "contact" ? contactError : dealError;
  const error = activeTab === "contact" ? contactErr : dealErr;

  return (
    <div
      className="flex flex-col min-h-full pb-20"
      style={{ background: "var(--bg-primary)" }}
    >
      {/* Page title */}
      <div className="flex items-center justify-between px-4 pt-3 pb-1">
        <h1
          className="text-lg font-bold"
          style={{ color: "var(--text-primary)" }}
        >
          Notes
        </h1>
        {!isLoading && (
          <span
            className="text-xs font-medium px-2 py-0.5 rounded-full"
            style={{
              background: "var(--bg-muted)",
              color: "var(--text-secondary)",
            }}
          >
            {activeTab === "contact"
              ? (contactNotes?.length ?? 0)
              : (dealNotes?.length ?? 0)}
          </span>
        )}
      </div>

      {/* Search */}
      <SearchBar
        value={search}
        onChange={setSearch}
        placeholder="Search notes..."
      />

      {/* Tab bar */}
      <div
        className="flex mx-4 mb-3 rounded-xl overflow-hidden"
        style={{ background: "var(--bg-muted)" }}
      >
        <button
          onClick={() => setActiveTab("contact")}
          className="flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-semibold transition-all rounded-xl"
          style={{
            background:
              activeTab === "contact" ? "var(--gold)" : "transparent",
            color: activeTab === "contact" ? "#fff" : "var(--text-muted)",
          }}
        >
          <User size={14} />
          Contact Notes
        </button>
        <button
          onClick={() => setActiveTab("deal")}
          className="flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-semibold transition-all rounded-xl"
          style={{
            background:
              activeTab === "deal" ? "var(--gold)" : "transparent",
            color: activeTab === "deal" ? "#fff" : "var(--text-muted)",
          }}
        >
          <Briefcase size={14} />
          Deal Notes
        </button>
      </div>

      {/* Loading */}
      {isLoading && <ListSkeleton count={6} />}

      {/* Error */}
      {isError && (
        <EmptyState
          icon={StickyNote}
          title="Failed to load notes"
          description={
            error instanceof Error
              ? error.message
              : "An unexpected error occurred. Pull down to retry."
          }
        />
      )}

      {/* ── Contact Notes Tab ──────────────────────────────────── */}
      {activeTab === "contact" &&
        !contactLoading &&
        !contactError &&
        contactNotes && (
          <>
            {contactNotes.length === 0 ? (
              <EmptyState
                icon={StickyNote}
                title={search ? "No matching notes" : "No contact notes yet"}
                description={
                  search
                    ? `No notes matching "${search}". Try a different search.`
                    : "Notes will appear here when added to contacts."
                }
              />
            ) : (
              <div className="flex flex-col gap-3 px-4">
                {contactNotes.map((note) => {
                  const contactName = note.contacts
                    ? `${note.contacts.first_name} ${note.contacts.last_name}`
                    : "Unknown Contact";
                  const authorName = note.sales
                    ? `${note.sales.first_name} ${note.sales.last_name}`
                    : "Unknown";
                  const statusColor = note.status
                    ? getStatusColor(note.status)
                    : undefined;

                  return (
                    <MobileCard key={note.id}>
                      {/* Top row: status badge + date */}
                      <div className="flex items-center justify-between mb-2">
                        {note.status ? (
                          <Badge variant={getStatusVariant(note.status)}>
                            {statusColor && (
                              <span
                                className="inline-block w-1.5 h-1.5 rounded-full"
                                style={{ backgroundColor: statusColor }}
                              />
                            )}
                            {note.status}
                          </Badge>
                        ) : (
                          <span />
                        )}
                        <span
                          className="text-[11px]"
                          style={{ color: "var(--text-muted)" }}
                        >
                          {formatRelativeDate(note.date)}
                        </span>
                      </div>

                      {/* Note text (truncated 3 lines) */}
                      <p
                        className="text-sm leading-relaxed mb-3"
                        style={{
                          color: "var(--text-primary)",
                          display: "-webkit-box",
                          WebkitLineClamp: 3,
                          WebkitBoxOrient: "vertical",
                          overflow: "hidden",
                        }}
                      >
                        {note.text}
                      </p>

                      {/* Footer: contact link + author */}
                      <div className="flex items-center justify-between">
                        <button
                          onClick={() =>
                            navigate(`/contacts/${note.contact_id}`)
                          }
                          className="flex items-center gap-1.5 text-xs font-medium transition-colors active:opacity-70"
                          style={{ color: "var(--gold)" }}
                        >
                          <User size={13} />
                          <span className="truncate max-w-[140px]">
                            {contactName}
                          </span>
                          <ChevronRight size={13} />
                        </button>
                        <span
                          className="text-[11px] truncate max-w-[120px]"
                          style={{ color: "var(--text-muted)" }}
                        >
                          {authorName}
                        </span>
                      </div>
                    </MobileCard>
                  );
                })}
              </div>
            )}
          </>
        )}

      {/* ── Deal Notes Tab ─────────────────────────────────────── */}
      {activeTab === "deal" &&
        !dealLoading &&
        !dealError &&
        dealNotes && (
          <>
            {dealNotes.length === 0 ? (
              <EmptyState
                icon={MessageSquare}
                title={search ? "No matching notes" : "No deal notes yet"}
                description={
                  search
                    ? `No notes matching "${search}". Try a different search.`
                    : "Notes will appear here when added to deals."
                }
              />
            ) : (
              <div className="flex flex-col gap-3 px-4">
                {dealNotes.map((note) => {
                  const dealName = note.deals?.name ?? "Unknown Deal";
                  const authorName = note.sales
                    ? `${note.sales.first_name} ${note.sales.last_name}`
                    : "Unknown";

                  return (
                    <MobileCard key={note.id}>
                      {/* Top row: icon + date */}
                      <div className="flex items-center justify-between mb-2">
                        <MessageSquare
                          size={14}
                          style={{ color: "var(--gold)" }}
                        />
                        <span
                          className="text-[11px]"
                          style={{ color: "var(--text-muted)" }}
                        >
                          {formatRelativeDate(note.date)}
                        </span>
                      </div>

                      {/* Note text (truncated 3 lines) */}
                      <p
                        className="text-sm leading-relaxed mb-3"
                        style={{
                          color: "var(--text-primary)",
                          display: "-webkit-box",
                          WebkitLineClamp: 3,
                          WebkitBoxOrient: "vertical",
                          overflow: "hidden",
                        }}
                      >
                        {note.text}
                      </p>

                      {/* Footer: deal link + author */}
                      <div className="flex items-center justify-between">
                        <button
                          onClick={() =>
                            navigate(`/deals/${note.deal_id}`)
                          }
                          className="flex items-center gap-1.5 text-xs font-medium transition-colors active:opacity-70"
                          style={{ color: "var(--gold)" }}
                        >
                          <Briefcase size={13} />
                          <span className="truncate max-w-[140px]">
                            {dealName}
                          </span>
                          <ChevronRight size={13} />
                        </button>
                        <span
                          className="text-[11px] truncate max-w-[120px]"
                          style={{ color: "var(--text-muted)" }}
                        >
                          {authorName}
                        </span>
                      </div>
                    </MobileCard>
                  );
                })}
              </div>
            )}
          </>
        )}
    </div>
  );
}
