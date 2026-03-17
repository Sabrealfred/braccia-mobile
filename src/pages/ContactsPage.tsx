import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ChevronRight, Users, UserPlus } from "lucide-react";
import { supabase } from "../lib/supabase";
import { formatRelativeDate } from "../lib/utils";
import { Avatar } from "../components/ui/Avatar";
import { SearchBar } from "../components/ui/SearchBar";
import { FAB } from "../components/ui/FAB";
import { Badge } from "../components/ui/Badge";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import { SectionTitle } from "../components/ui/MobileCard";
import type { Client } from "../types";

// ---------------------------------------------------------------------------
// Status badge variant mapping (clients table)
// ---------------------------------------------------------------------------

type StatusVariant = "success" | "warning" | "info" | "danger" | "default";

const statusVariantMap: Record<string, StatusVariant> = {
  active: "success",
  prospect: "warning",
  inactive: "info",
  archived: "default",
};

function getStatusVariant(status: string): StatusVariant {
  return statusVariantMap[status?.toLowerCase()] ?? "default";
}

const clientTypeVariant: Record<string, StatusVariant> = {
  individual: "info",
  entity: "warning",
};

function getClientTypeVariant(type: string): StatusVariant {
  return clientTypeVariant[type?.toLowerCase()] ?? "default";
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Return display name: prefer full_name, fallback to name */
function displayName(client: Client): string {
  return client.full_name || client.name || "Unnamed";
}

/** Split a display name into [firstName, lastName] for avatar initials */
function splitName(client: Client): [string, string] {
  const raw = displayName(client);
  const parts = raw.trim().split(/\s+/);
  return [parts[0] ?? "", parts.slice(1).join(" ") || ""];
}

// ---------------------------------------------------------------------------
// Data fetching
// ---------------------------------------------------------------------------

async function fetchClients(search: string): Promise<Client[]> {
  let query = supabase
    .from("clients")
    .select("*")
    .order("updated_at", { ascending: false });

  if (search.trim()) {
    const term = search.trim();
    query = query.or(
      `full_name.ilike.%${term}%,name.ilike.%${term}%,email.ilike.%${term}%`
    );
  }

  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

// ---------------------------------------------------------------------------
// Grouping by first letter
// ---------------------------------------------------------------------------

interface LetterGroup {
  letter: string;
  clients: Client[];
}

function groupByFirstLetter(clients: Client[]): LetterGroup[] {
  const groups = new Map<string, Client[]>();

  for (const client of clients) {
    const raw = displayName(client);
    const letter = raw.charAt(0)?.toUpperCase() || "#";
    const validLetter = /^[A-Z]$/.test(letter) ? letter : "#";
    if (!groups.has(validLetter)) {
      groups.set(validLetter, []);
    }
    groups.get(validLetter)!.push(client);
  }

  return Array.from(groups.entries())
    .sort(([a], [b]) => {
      if (a === "#") return 1;
      if (b === "#") return -1;
      return a.localeCompare(b);
    })
    .map(([letter, clients]) => ({
      letter,
      clients: clients.sort((a, b) =>
        displayName(a).localeCompare(displayName(b))
      ),
    }));
}

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

export function ContactsPage() {
  const [search, setSearch] = useState("");
  const navigate = useNavigate();

  const {
    data: clients,
    isLoading,
    isError,
    error,
  } = useQuery<Client[]>({
    queryKey: ["clients", search],
    queryFn: () => fetchClients(search),
  });

  const groups = useMemo(() => {
    if (!clients) return [];
    return groupByFirstLetter(clients);
  }, [clients]);

  const totalCount = clients?.length ?? 0;

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
          Contacts
        </h1>
        {!isLoading && totalCount > 0 && (
          <span
            className="text-xs font-medium px-2 py-0.5 rounded-full"
            style={{
              background: "var(--bg-muted)",
              color: "var(--text-secondary)",
            }}
          >
            {totalCount}
          </span>
        )}
      </div>

      {/* Search */}
      <SearchBar
        value={search}
        onChange={setSearch}
        placeholder="Search contacts..."
      />

      {/* Loading */}
      {isLoading && <ListSkeleton count={8} />}

      {/* Error */}
      {isError && (
        <EmptyState
          icon={Users}
          title="Failed to load contacts"
          description={
            error instanceof Error
              ? error.message
              : "An unexpected error occurred. Pull down to retry."
          }
        />
      )}

      {/* Empty states */}
      {!isLoading && !isError && totalCount === 0 && (
        <EmptyState
          icon={Users}
          title={search ? "No matches found" : "No contacts yet"}
          description={
            search
              ? `No contacts matching "${search}". Try a different search.`
              : "Add your first contact to get started."
          }
          action={
            !search ? (
              <button
                onClick={() => navigate("/contacts/create")}
                className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-transform active:scale-95"
                style={{ background: "var(--gold)", color: "var(--white)" }}
              >
                <UserPlus size={16} />
                Add Contact
              </button>
            ) : undefined
          }
        />
      )}

      {/* Grouped client list */}
      {!isLoading && !isError && totalCount > 0 && (
        <div className="flex flex-col">
          {groups.map((group) => (
            <div key={group.letter}>
              {/* Section header */}
              <SectionTitle count={group.clients.length}>
                {group.letter}
              </SectionTitle>

              {/* Client rows */}
              <div>
                {group.clients.map((client) => {
                  const [firstName, lastName] = splitName(client);

                  return (
                    <button
                      key={client.id}
                      onClick={() => navigate(`/contacts/${client.id}`)}
                      className="flex items-center gap-3 w-full px-4 py-3 text-left transition-colors active:bg-[var(--bg-muted)]"
                      style={{
                        borderBottom: "1px solid var(--border-light)",
                      }}
                    >
                      {/* Avatar */}
                      <Avatar
                        firstName={firstName}
                        lastName={lastName}
                        size="md"
                      />

                      {/* Info block */}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span
                            className="text-sm font-semibold truncate"
                            style={{ color: "var(--text-primary)" }}
                          >
                            {displayName(client)}
                          </span>
                          {client.status && (
                            <Badge variant={getStatusVariant(client.status)}>
                              {client.status}
                            </Badge>
                          )}
                        </div>

                        {/* Company + Client Type */}
                        <div className="flex items-center gap-2 mt-0.5">
                          <p
                            className="text-xs truncate"
                            style={{ color: "var(--text-secondary)" }}
                          >
                            {client.company || "No company"}
                          </p>
                          {client.client_type && (
                            <Badge
                              variant={getClientTypeVariant(client.client_type)}
                            >
                              {client.client_type}
                            </Badge>
                          )}
                        </div>

                        {/* Updated at */}
                        {client.updated_at && (
                          <p
                            className="text-[11px] mt-0.5"
                            style={{ color: "var(--text-muted)" }}
                          >
                            {formatRelativeDate(client.updated_at)}
                          </p>
                        )}
                      </div>

                      {/* Chevron */}
                      <ChevronRight
                        size={18}
                        style={{ color: "var(--text-muted)", flexShrink: 0 }}
                      />
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Floating action button */}
      <FAB
        to="/contacts/create"
        label="New Contact"
        icon={<UserPlus size={18} />}
      />
    </div>
  );
}
