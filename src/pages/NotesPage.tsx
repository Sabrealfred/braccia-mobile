import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { StickyNote, MessageSquare, ChevronRight, User, Briefcase } from "lucide-react";
import { supabase } from "../lib/supabase";
import { formatRelativeDate } from "../lib/utils";
import { SearchBar } from "../components/ui/SearchBar";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import { MobileCard } from "../components/ui/MobileCard";
import type { ConsultantNote } from "../types";

// -- Types with joined relations --

interface NoteWithClient extends ConsultantNote {
  clients?: { name: string } | null;
}

interface NoteWithDeal extends ConsultantNote {
  deals?: { name: string } | null;
}

// -- Data fetchers --

async function fetchClientNotes(search: string): Promise<NoteWithClient[]> {
  try {
    let query = supabase
      .from("consultant_notes")
      .select("*, clients(name)")
      .not("client_id", "is", null)
      .order("created_at", { ascending: false });

    if (search.trim()) {
      query = query.ilike("text", `%${search.trim()}%`);
    }

    const { data, error } = await query;
    if (error) throw error;
    return (data as NoteWithClient[]) ?? [];
  } catch (err) {
    // If table doesn't exist, return empty array gracefully
    console.warn("consultant_notes query failed:", err);
    return [];
  }
}

async function fetchDealNotes(search: string): Promise<NoteWithDeal[]> {
  try {
    let query = supabase
      .from("consultant_notes")
      .select("*, deals(name)")
      .not("deal_id", "is", null)
      .order("created_at", { ascending: false });

    if (search.trim()) {
      query = query.ilike("text", `%${search.trim()}%`);
    }

    const { data, error } = await query;
    if (error) throw error;
    return (data as NoteWithDeal[]) ?? [];
  } catch (err) {
    console.warn("consultant_notes (deal) query failed:", err);
    return [];
  }
}

// -- Tabs --

type Tab = "client" | "deal";

// -- Page Component --

export function NotesPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [activeTab, setActiveTab] = useState<Tab>("client");

  // Client notes query
  const {
    data: clientNotes,
    isLoading: clientLoading,
    isError: clientError,
    error: clientErr,
  } = useQuery<NoteWithClient[]>({
    queryKey: ["clientNotes", search],
    queryFn: () => fetchClientNotes(search),
    enabled: activeTab === "client",
  });

  // Deal notes query
  const {
    data: dealNotes,
    isLoading: dealLoading,
    isError: dealError,
    error: dealErr,
  } = useQuery<NoteWithDeal[]>({
    queryKey: ["dealNotes", search],
    queryFn: () => fetchDealNotes(search),
    enabled: activeTab === "deal",
  });

  const isLoading = activeTab === "client" ? clientLoading : dealLoading;
  const isError = activeTab === "client" ? clientError : dealError;
  const error = activeTab === "client" ? clientErr : dealErr;

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
            {activeTab === "client"
              ? (clientNotes?.length ?? 0)
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
          onClick={() => setActiveTab("client")}
          className="flex-1 flex items-center justify-center gap-1.5 py-2.5 text-xs font-semibold transition-all rounded-xl"
          style={{
            background:
              activeTab === "client" ? "var(--gold)" : "transparent",
            color: activeTab === "client" ? "#fff" : "var(--text-muted)",
          }}
        >
          <User size={14} />
          Client Notes
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

      {/* -- Client Notes Tab -- */}
      {activeTab === "client" &&
        !clientLoading &&
        !clientError &&
        clientNotes && (
          <>
            {clientNotes.length === 0 ? (
              <EmptyState
                icon={StickyNote}
                title={search ? "No matching notes" : "No client notes yet"}
                description={
                  search
                    ? `No notes matching "${search}". Try a different search.`
                    : "Notes will appear here when added to clients."
                }
              />
            ) : (
              <div className="flex flex-col gap-3 px-4">
                {clientNotes.map((note) => {
                  const clientName = note.clients?.name ?? "Unknown Client";

                  return (
                    <MobileCard key={note.id}>
                      {/* Top row: status + date */}
                      <div className="flex items-center justify-between mb-2">
                        {note.status ? (
                          <span
                            className="text-[10px] font-semibold uppercase tracking-wide px-2 py-0.5 rounded-full"
                            style={{
                              background: "var(--bg-muted)",
                              color: "var(--text-secondary)",
                            }}
                          >
                            {note.status}
                          </span>
                        ) : (
                          <span />
                        )}
                        <span
                          className="text-[11px]"
                          style={{ color: "var(--text-muted)" }}
                        >
                          {formatRelativeDate(note.created_at)}
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

                      {/* Footer: client link */}
                      <div className="flex items-center justify-between">
                        <button
                          onClick={() =>
                            navigate(`/clients/${note.client_id}`)
                          }
                          className="flex items-center gap-1.5 text-xs font-medium transition-colors active:opacity-70"
                          style={{ color: "var(--gold)" }}
                        >
                          <User size={13} />
                          <span className="truncate max-w-[140px]">
                            {clientName}
                          </span>
                          <ChevronRight size={13} />
                        </button>
                      </div>
                    </MobileCard>
                  );
                })}
              </div>
            )}
          </>
        )}

      {/* -- Deal Notes Tab -- */}
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
                          {formatRelativeDate(note.created_at)}
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

                      {/* Footer: deal link */}
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
