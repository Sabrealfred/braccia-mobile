import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { formatDate, formatRelativeDate } from "../lib/utils";
import type { Contact, ContactNote, Task, Tag } from "../types";
import { Avatar } from "../components/ui/Avatar";
import { Badge } from "../components/ui/Badge";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard } from "../components/ui/MobileCard";
import { SectionTitle } from "../components/ui/MobileCard";
import { Skeleton } from "../components/ui/Skeleton";
import {
  Pencil,
  Mail,
  Phone,
  Linkedin,
  StickyNote,
  CheckSquare,
  Square,
  TagIcon,
  Calendar,
  User,
  Briefcase,
  ExternalLink,
} from "lucide-react";

// ---------------------------------------------------------------------------
// Status badge variant mapping
// ---------------------------------------------------------------------------
const statusVariant: Record<string, "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline"> = {
  cold: "info",
  warm: "warning",
  hot: "danger",
  "in-contract": "gold",
  "closed-won": "success",
  "closed-lost": "default",
};

function getStatusVariant(status: string) {
  return statusVariant[status?.toLowerCase()] ?? "default";
}

const noteStatusVariant: Record<string, "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline"> = {
  cold: "info",
  warm: "warning",
  hot: "danger",
  "reached-out": "gold",
  "follow-up": "warning",
  "meeting-scheduled": "info",
  "closed-won": "success",
  "closed-lost": "default",
};

function getNoteStatusVariant(status: string) {
  return noteStatusVariant[status?.toLowerCase()] ?? "outline";
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

interface ContactWithCompany extends Contact {
  companies?: { name: string } | null;
}

function HeroSection({ contact }: { contact: ContactWithCompany }) {
  const companyName = contact.companies?.name ?? contact.company_name;

  return (
    <div className="flex flex-col items-center pt-2 pb-5 px-4">
      <Avatar
        firstName={contact.first_name}
        lastName={contact.last_name}
        src={contact.avatar?.src}
        size="xl"
      />
      <h2
        className="mt-3 text-xl font-bold text-center"
        style={{ color: "var(--text-primary)" }}
      >
        {contact.first_name} {contact.last_name}
      </h2>
      {contact.title && (
        <p
          className="mt-0.5 text-sm text-center"
          style={{ color: "var(--text-secondary)" }}
        >
          {contact.title}
        </p>
      )}
      {companyName && (
        <p
          className="mt-0.5 text-xs text-center flex items-center gap-1"
          style={{ color: "var(--text-muted)" }}
        >
          <Briefcase size={12} />
          {companyName}
        </p>
      )}
      <div className="flex items-center gap-2 mt-3">
        <Badge variant={getStatusVariant(contact.status)}>
          {contact.status}
        </Badge>
        {contact.gender && (
          <Badge variant="outline">{contact.gender}</Badge>
        )}
      </div>
    </div>
  );
}

function ContactInfoSection({ contact }: { contact: ContactWithCompany }) {
  const emails = contact.email_jsonb ?? [];
  const phones = contact.phone_jsonb ?? [];
  const hasInfo = emails.length > 0 || phones.length > 0 || contact.linkedin_url;

  if (!hasInfo) return null;

  return (
    <div className="px-4 space-y-3">
      <SectionTitle>Contact Info</SectionTitle>

      {/* Emails */}
      {emails.length > 0 && (
        <MobileCard>
          {emails.map((entry, idx) => (
            <a
              key={idx}
              href={`mailto:${entry.email}`}
              className="flex items-center gap-3 py-2"
              style={{
                color: "var(--text-primary)",
                textDecoration: "none",
                borderBottom:
                  idx < emails.length - 1
                    ? "1px solid var(--border-light)"
                    : "none",
              }}
            >
              <div
                className="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
                style={{ background: "var(--bg-muted)" }}
              >
                <Mail size={14} style={{ color: "var(--text-secondary)" }} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm truncate">{entry.email}</p>
                <p className="text-[11px]" style={{ color: "var(--text-muted)" }}>
                  {entry.type}
                </p>
              </div>
              <ExternalLink
                size={14}
                style={{ color: "var(--text-muted)", flexShrink: 0 }}
              />
            </a>
          ))}
        </MobileCard>
      )}

      {/* Phones */}
      {phones.length > 0 && (
        <MobileCard>
          {phones.map((entry, idx) => (
            <a
              key={idx}
              href={`tel:${entry.number}`}
              className="flex items-center gap-3 py-2"
              style={{
                color: "var(--text-primary)",
                textDecoration: "none",
                borderBottom:
                  idx < phones.length - 1
                    ? "1px solid var(--border-light)"
                    : "none",
              }}
            >
              <div
                className="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
                style={{ background: "var(--bg-muted)" }}
              >
                <Phone size={14} style={{ color: "var(--text-secondary)" }} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm truncate">{entry.number}</p>
                <p className="text-[11px]" style={{ color: "var(--text-muted)" }}>
                  {entry.type}
                </p>
              </div>
              <ExternalLink
                size={14}
                style={{ color: "var(--text-muted)", flexShrink: 0 }}
              />
            </a>
          ))}
        </MobileCard>
      )}

      {/* LinkedIn */}
      {contact.linkedin_url && (
        <MobileCard>
          <a
            href={contact.linkedin_url}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-3 py-1"
            style={{ color: "var(--text-primary)", textDecoration: "none" }}
          >
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
              style={{ background: "#0A66C2" }}
            >
              <Linkedin size={14} style={{ color: "#ffffff" }} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm truncate">LinkedIn Profile</p>
              <p
                className="text-[11px] truncate"
                style={{ color: "var(--text-muted)" }}
              >
                {contact.linkedin_url.replace(/^https?:\/\/(www\.)?/, "")}
              </p>
            </div>
            <ExternalLink
              size={14}
              style={{ color: "var(--text-muted)", flexShrink: 0 }}
            />
          </a>
        </MobileCard>
      )}
    </div>
  );
}

function MetaSection({ contact }: { contact: ContactWithCompany }) {
  return (
    <div className="px-4">
      <MobileCard>
        <div className="grid grid-cols-2 gap-y-3 gap-x-4">
          <div>
            <p className="text-[11px] uppercase tracking-wider font-medium" style={{ color: "var(--text-muted)" }}>
              First Seen
            </p>
            <p className="text-sm mt-0.5" style={{ color: "var(--text-primary)" }}>
              {formatDate(contact.first_seen)}
            </p>
          </div>
          <div>
            <p className="text-[11px] uppercase tracking-wider font-medium" style={{ color: "var(--text-muted)" }}>
              Last Seen
            </p>
            <p className="text-sm mt-0.5" style={{ color: "var(--text-primary)" }}>
              {formatRelativeDate(contact.last_seen)}
            </p>
          </div>
          {contact.has_newsletter && (
            <div className="col-span-2">
              <Badge variant="success">Subscribed to newsletter</Badge>
            </div>
          )}
        </div>
      </MobileCard>
    </div>
  );
}

function BackgroundSection({ background }: { background: string }) {
  return (
    <div className="px-4">
      <SectionTitle>Background</SectionTitle>
      <MobileCard>
        <p className="text-sm leading-relaxed whitespace-pre-wrap" style={{ color: "var(--text-secondary)" }}>
          {background}
        </p>
      </MobileCard>
    </div>
  );
}

function NotesSection({ notes }: { notes: ContactNote[] }) {
  if (notes.length === 0) {
    return (
      <div className="px-4">
        <SectionTitle count={0}>Notes</SectionTitle>
        <div className="flex flex-col items-center py-8">
          <StickyNote size={32} strokeWidth={1.2} style={{ color: "var(--text-muted)", opacity: 0.4 }} />
          <p className="text-xs mt-2" style={{ color: "var(--text-muted)" }}>
            No notes yet
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="px-4">
      <SectionTitle count={notes.length}>Notes</SectionTitle>
      <div className="space-y-2">
        {notes.map((note) => (
          <MobileCard key={note.id}>
            <div className="flex items-start justify-between gap-2 mb-1.5">
              <div className="flex items-center gap-1.5">
                <Calendar size={12} style={{ color: "var(--text-muted)" }} />
                <span className="text-[11px] font-medium" style={{ color: "var(--text-muted)" }}>
                  {formatDate(note.date)}
                </span>
              </div>
              {note.status && (
                <Badge variant={getNoteStatusVariant(note.status)}>
                  {note.status}
                </Badge>
              )}
            </div>
            <p
              className="text-sm leading-relaxed whitespace-pre-wrap"
              style={{ color: "var(--text-primary)" }}
            >
              {note.text}
            </p>
            {note.sales_id && (
              <div className="flex items-center gap-1 mt-2">
                <User size={11} style={{ color: "var(--text-muted)" }} />
                <span className="text-[10px]" style={{ color: "var(--text-muted)" }}>
                  Sales #{note.sales_id}
                </span>
              </div>
            )}
          </MobileCard>
        ))}
      </div>
    </div>
  );
}

function TasksSection({ tasks }: { tasks: Task[] }) {
  if (tasks.length === 0) {
    return (
      <div className="px-4">
        <SectionTitle count={0}>Tasks</SectionTitle>
        <div className="flex flex-col items-center py-8">
          <CheckSquare size={32} strokeWidth={1.2} style={{ color: "var(--text-muted)", opacity: 0.4 }} />
          <p className="text-xs mt-2" style={{ color: "var(--text-muted)" }}>
            No tasks assigned
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="px-4">
      <SectionTitle count={tasks.length}>Tasks</SectionTitle>
      <MobileCard noPadding>
        {tasks.map((task, idx) => {
          const isDone = !!task.done_date;
          const isOverdue =
            !isDone && task.due_date && new Date(task.due_date) < new Date();

          return (
            <div
              key={task.id}
              className="flex items-start gap-3 px-4 py-3"
              style={{
                borderBottom:
                  idx < tasks.length - 1
                    ? "1px solid var(--border-light)"
                    : "none",
                opacity: isDone ? 0.55 : 1,
              }}
            >
              {isDone ? (
                <CheckSquare
                  size={18}
                  className="mt-0.5 shrink-0"
                  style={{ color: "var(--success)" }}
                />
              ) : (
                <Square
                  size={18}
                  className="mt-0.5 shrink-0"
                  style={{ color: "var(--text-muted)" }}
                />
              )}
              <div className="flex-1 min-w-0">
                <p
                  className="text-sm"
                  style={{
                    color: "var(--text-primary)",
                    textDecoration: isDone ? "line-through" : "none",
                  }}
                >
                  {task.text}
                </p>
                <div className="flex items-center gap-2 mt-1">
                  {task.type && (
                    <Badge variant="outline">{task.type}</Badge>
                  )}
                  {task.due_date && (
                    <span
                      className="text-[11px] font-medium"
                      style={{
                        color: isOverdue ? "var(--danger)" : "var(--text-muted)",
                      }}
                    >
                      {formatRelativeDate(task.due_date)}
                    </span>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </MobileCard>
    </div>
  );
}

function TagsSection({ contactTags, allTags }: { contactTags: number[]; allTags: Tag[] }) {
  const matched = allTags.filter((t) => contactTags.includes(t.id));
  if (matched.length === 0) return null;

  return (
    <div className="px-4">
      <SectionTitle count={matched.length}>Tags</SectionTitle>
      <div className="flex flex-wrap gap-2">
        {matched.map((tag) => (
          <span
            key={tag.id}
            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium"
            style={{
              background: `${tag.color}22`,
              color: tag.color,
              border: `1px solid ${tag.color}44`,
            }}
          >
            <TagIcon size={10} />
            {tag.name}
          </span>
        ))}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

function ContactDetailSkeleton() {
  return (
    <div className="space-y-4 pb-8">
      {/* Hero skeleton */}
      <div className="flex flex-col items-center pt-6 pb-4 px-4">
        <Skeleton className="w-16 h-16 rounded-full" />
        <Skeleton className="h-5 w-40 mt-3" />
        <Skeleton className="h-3.5 w-28 mt-2" />
        <Skeleton className="h-3 w-24 mt-1.5" />
        <div className="flex gap-2 mt-3">
          <Skeleton className="h-5 w-14 rounded-full" />
          <Skeleton className="h-5 w-12 rounded-full" />
        </div>
      </div>

      {/* Info cards skeleton */}
      <div className="px-4 space-y-3">
        <Skeleton className="h-3 w-24" />
        <div className="card-mobile p-4 space-y-3">
          <div className="flex items-center gap-3">
            <Skeleton className="w-8 h-8 rounded-full" />
            <div className="flex-1 space-y-1.5">
              <Skeleton className="h-3.5 w-48" />
              <Skeleton className="h-2.5 w-16" />
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Skeleton className="w-8 h-8 rounded-full" />
            <div className="flex-1 space-y-1.5">
              <Skeleton className="h-3.5 w-36" />
              <Skeleton className="h-2.5 w-16" />
            </div>
          </div>
        </div>
      </div>

      {/* Notes skeleton */}
      <div className="px-4 space-y-3">
        <Skeleton className="h-3 w-16" />
        <div className="card-mobile p-4 space-y-2">
          <Skeleton className="h-3 w-24" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-3/4" />
        </div>
      </div>

      {/* Tasks skeleton */}
      <div className="px-4 space-y-3">
        <Skeleton className="h-3 w-16" />
        <div className="card-mobile p-4 space-y-3">
          <div className="flex items-center gap-3">
            <Skeleton className="w-4.5 h-4.5" />
            <Skeleton className="h-3.5 w-48" />
          </div>
          <div className="flex items-center gap-3">
            <Skeleton className="w-4.5 h-4.5" />
            <Skeleton className="h-3.5 w-40" />
          </div>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

function ErrorState({ message }: { message: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 px-8 text-center">
      <User size={48} strokeWidth={1.2} style={{ color: "var(--text-muted)", opacity: 0.4 }} />
      <h3 className="mt-4 text-base font-semibold" style={{ color: "var(--text-secondary)" }}>
        Contact Not Found
      </h3>
      <p className="mt-1.5 text-sm max-w-xs" style={{ color: "var(--text-muted)" }}>
        {message}
      </p>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main page component
// ---------------------------------------------------------------------------

export function ContactDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  // ---- Contact query ----
  const {
    data: contact,
    isLoading: contactLoading,
    error: contactError,
  } = useQuery<ContactWithCompany>({
    queryKey: ["contact", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("contacts")
        .select("*, companies(name)")
        .eq("id", id!)
        .single();
      if (error) throw error;
      return data as ContactWithCompany;
    },
    enabled: !!id,
  });

  // ---- Notes query ----
  const { data: notes = [] } = useQuery<ContactNote[]>({
    queryKey: ["contact-notes", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("contactNotes")
        .select("*")
        .eq("contact_id", id!)
        .order("date", { ascending: false });
      if (error) throw error;
      return (data ?? []) as ContactNote[];
    },
    enabled: !!id,
  });

  // ---- Tasks query ----
  const { data: tasks = [] } = useQuery<Task[]>({
    queryKey: ["contact-tasks", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("tasks")
        .select("*")
        .eq("contact_id", id!)
        .order("due_date");
      if (error) throw error;
      return (data ?? []) as Task[];
    },
    enabled: !!id,
  });

  // ---- Tags query ----
  const { data: allTags = [] } = useQuery<Tag[]>({
    queryKey: ["tags"],
    queryFn: async () => {
      const { data, error } = await supabase.from("tags").select("*");
      if (error) throw error;
      return (data ?? []) as Tag[];
    },
  });

  // ---- Render ----

  if (contactLoading) {
    return (
      <div>
        <PageHeader title="Contact" back="/contacts" />
        <ContactDetailSkeleton />
      </div>
    );
  }

  if (contactError || !contact) {
    return (
      <div>
        <PageHeader title="Contact" back="/contacts" />
        <ErrorState
          message={
            contactError instanceof Error
              ? contactError.message
              : "Could not load this contact. It may have been deleted."
          }
        />
      </div>
    );
  }

  return (
    <div className="pb-6">
      <PageHeader
        title={`${contact.first_name} ${contact.last_name}`}
        back="/contacts"
        actions={
          <button
            onClick={() => navigate(`/contacts/${id}?edit=true`)}
            className="p-2 rounded-full active:bg-[var(--bg-muted)] transition-colors"
            aria-label="Edit contact"
          >
            <Pencil size={18} style={{ color: "var(--text-gold)" }} />
          </button>
        }
      />

      <div className="space-y-4">
        {/* Hero */}
        <HeroSection contact={contact} />

        {/* Contact info: emails, phones, linkedin */}
        <ContactInfoSection contact={contact} />

        {/* Meta: first seen, last seen, newsletter */}
        <MetaSection contact={contact} />

        {/* Background */}
        {contact.background && (
          <BackgroundSection background={contact.background} />
        )}

        {/* Tags */}
        {contact.tags && contact.tags.length > 0 && (
          <TagsSection contactTags={contact.tags} allTags={allTags} />
        )}

        {/* Notes */}
        <NotesSection notes={notes} />

        {/* Tasks */}
        <TasksSection tasks={tasks} />
      </div>
    </div>
  );
}
