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
import type { Contact } from "../types";

type StatusVariant = "danger" | "warning" | "info" | "default";

const statusVariantMap: Record<string, StatusVariant> = {
  hot: "danger",
  warm: "warning",
  cold: "info",
};

function getStatusVariant(status: string): StatusVariant {
  return statusVariantMap[status.toLowerCase()] ?? "default";
}

async function fetchContacts(search: string): Promise<Contact[]> {
  let query = supabase
    .from("contacts_summary")
    .select("*")
    .order("last_seen", { ascending: false });

  if (search.trim()) {
    const term = search.trim();
    query = query.or(
      `first_name.ilike.%${term}%,last_name.ilike.%${term}%`
    );
  }

  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

interface LetterGroup {
  letter: string;
  contacts: Contact[];
}

function groupByLastNameLetter(contacts: Contact[]): LetterGroup[] {
  const groups = new Map<string, Contact[]>();

  for (const contact of contacts) {
    const letter =
      contact.last_name?.charAt(0)?.toUpperCase() || "#";
    const validLetter = /^[A-Z]$/.test(letter) ? letter : "#";
    if (!groups.has(validLetter)) {
      groups.set(validLetter, []);
    }
    groups.get(validLetter)!.push(contact);
  }

  return Array.from(groups.entries())
    .sort(([a], [b]) => {
      if (a === "#") return 1;
      if (b === "#") return -1;
      return a.localeCompare(b);
    })
    .map(([letter, contacts]) => ({
      letter,
      contacts: contacts.sort((a, b) =>
        (a.last_name ?? "").localeCompare(b.last_name ?? "")
      ),
    }));
}

export function ContactsPage() {
  const [search, setSearch] = useState("");
  const navigate = useNavigate();

  const {
    data: contacts,
    isLoading,
    isError,
    error,
  } = useQuery<Contact[]>({
    queryKey: ["contacts", search],
    queryFn: () => fetchContacts(search),
  });

  const groups = useMemo(() => {
    if (!contacts) return [];
    return groupByLastNameLetter(contacts);
  }, [contacts]);

  const totalCount = contacts?.length ?? 0;

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

      {/* Grouped contact list */}
      {!isLoading && !isError && totalCount > 0 && (
        <div className="flex flex-col">
          {groups.map((group) => (
            <div key={group.letter}>
              {/* Section header */}
              <SectionTitle count={group.contacts.length}>
                {group.letter}
              </SectionTitle>

              {/* Contact rows */}
              <div>
                {group.contacts.map((contact) => (
                  <button
                    key={contact.id}
                    onClick={() => navigate(`/contacts/${contact.id}`)}
                    className="flex items-center gap-3 w-full px-4 py-3 text-left transition-colors active:bg-[var(--bg-muted)]"
                    style={{
                      borderBottom: "1px solid var(--border-light)",
                    }}
                  >
                    {/* Avatar */}
                    <Avatar
                      firstName={contact.first_name}
                      lastName={contact.last_name}
                      src={contact.avatar?.src}
                      size="md"
                    />

                    {/* Info block */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span
                          className="text-sm font-semibold truncate"
                          style={{ color: "var(--text-primary)" }}
                        >
                          {contact.first_name} {contact.last_name}
                        </span>
                        {contact.status && (
                          <Badge variant={getStatusVariant(contact.status)}>
                            {contact.status}
                          </Badge>
                        )}
                      </div>

                      {/* Title + Company */}
                      <p
                        className="text-xs truncate mt-0.5"
                        style={{ color: "var(--text-secondary)" }}
                      >
                        {[contact.title, contact.company_name]
                          .filter(Boolean)
                          .join(" · ") || "No title"}
                      </p>

                      {/* Last seen */}
                      {contact.last_seen && (
                        <p
                          className="text-[11px] mt-0.5"
                          style={{ color: "var(--text-muted)" }}
                        >
                          {formatRelativeDate(contact.last_seen)}
                        </p>
                      )}
                    </div>

                    {/* Chevron */}
                    <ChevronRight
                      size={18}
                      style={{ color: "var(--text-muted)", flexShrink: 0 }}
                    />
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Floating action button */}
      <FAB to="/contacts/create" label="New Contact" icon={<UserPlus size={18} />} />
    </div>
  );
}
