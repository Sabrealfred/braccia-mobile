import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { formatDate, formatCurrency, formatRelativeDate } from "../lib/utils";
import type { Client, Deal, Task } from "../types";
import { Avatar } from "../components/ui/Avatar";
import { Badge } from "../components/ui/Badge";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Skeleton } from "../components/ui/Skeleton";
import {
  Pencil,
  Mail,
  Phone,
  Globe,
  MapPin,
  DollarSign,
  Shield,
  ShieldCheck,
  FileText,
  Tag as TagIcon,
  Briefcase,
  ExternalLink,
  CheckSquare,
  Square,
  User,
  Building2,
} from "lucide-react";

// ---------------------------------------------------------------------------
// Status badge variant mapping
// ---------------------------------------------------------------------------

type BadgeVariant = "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline";

const statusVariant: Record<string, BadgeVariant> = {
  active: "success",
  prospect: "warning",
  inactive: "info",
  archived: "default",
};

function getStatusVariant(status: string): BadgeVariant {
  return statusVariant[status?.toLowerCase()] ?? "default";
}

const clientTypeVariant: Record<string, BadgeVariant> = {
  individual: "info",
  entity: "gold",
};

function getClientTypeVariant(type: string): BadgeVariant {
  return clientTypeVariant[type?.toLowerCase()] ?? "outline";
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function displayName(client: Client): string {
  return client.full_name || client.name || "Unnamed";
}

function splitName(client: Client): [string, string] {
  const raw = displayName(client);
  const parts = raw.trim().split(/\s+/);
  return [parts[0] ?? "", parts.slice(1).join(" ") || ""];
}

function buildAddress(client: Client): string | null {
  const parts = [
    client.address_line1,
    client.address_line2,
    client.city,
    client.state,
    client.postal_code,
    client.country,
  ].filter(Boolean);
  return parts.length > 0 ? parts.join(", ") : null;
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

function HeroSection({ client }: { client: Client }) {
  const [firstName, lastName] = splitName(client);

  return (
    <div className="flex flex-col items-center pt-2 pb-5 px-4">
      <Avatar firstName={firstName} lastName={lastName} size="xl" />
      <h2
        className="mt-3 text-xl font-bold text-center"
        style={{ color: "var(--text-primary)" }}
      >
        {displayName(client)}
      </h2>
      {client.company && (
        <p
          className="mt-0.5 text-sm text-center flex items-center gap-1"
          style={{ color: "var(--text-secondary)" }}
        >
          <Briefcase size={12} />
          {client.company}
        </p>
      )}
      {client.industry && (
        <p
          className="mt-0.5 text-xs text-center flex items-center gap-1"
          style={{ color: "var(--text-muted)" }}
        >
          <Building2 size={11} />
          {client.industry}
        </p>
      )}
      <div className="flex items-center gap-2 mt-3">
        {client.status && (
          <Badge variant={getStatusVariant(client.status)}>
            {client.status}
          </Badge>
        )}
        {client.client_type && (
          <Badge variant={getClientTypeVariant(client.client_type)}>
            {client.client_type}
          </Badge>
        )}
      </div>
    </div>
  );
}

function ContactInfoSection({ client }: { client: Client }) {
  const emails = [
    client.primary_email && { value: client.primary_email, label: "Primary" },
    client.secondary_email && { value: client.secondary_email, label: "Secondary" },
  ].filter(Boolean) as { value: string; label: string }[];

  const phones = [
    client.primary_phone && { value: client.primary_phone, label: "Primary" },
    client.secondary_phone && { value: client.secondary_phone, label: "Secondary" },
  ].filter(Boolean) as { value: string; label: string }[];

  const address = buildAddress(client);
  const hasInfo = emails.length > 0 || phones.length > 0 || client.website || address;

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
              href={`mailto:${entry.value}`}
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
                <p className="text-sm truncate">{entry.value}</p>
                <p
                  className="text-[11px]"
                  style={{ color: "var(--text-muted)" }}
                >
                  {entry.label}
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
              href={`tel:${entry.value}`}
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
                <p className="text-sm truncate">{entry.value}</p>
                <p
                  className="text-[11px]"
                  style={{ color: "var(--text-muted)" }}
                >
                  {entry.label}
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

      {/* Website */}
      {client.website && (
        <MobileCard>
          <a
            href={
              client.website.startsWith("http")
                ? client.website
                : `https://${client.website}`
            }
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-3 py-1"
            style={{ color: "var(--text-primary)", textDecoration: "none" }}
          >
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
              style={{ background: "var(--bg-muted)" }}
            >
              <Globe size={14} style={{ color: "var(--text-secondary)" }} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm truncate">Website</p>
              <p
                className="text-[11px] truncate"
                style={{ color: "var(--text-muted)" }}
              >
                {client.website.replace(/^https?:\/\/(www\.)?/, "")}
              </p>
            </div>
            <ExternalLink
              size={14}
              style={{ color: "var(--text-muted)", flexShrink: 0 }}
            />
          </a>
        </MobileCard>
      )}

      {/* Address */}
      {address && (
        <MobileCard>
          <div className="flex items-start gap-3 py-1">
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
              style={{ background: "var(--bg-muted)" }}
            >
              <MapPin size={14} style={{ color: "var(--text-secondary)" }} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm">{address}</p>
            </div>
          </div>
        </MobileCard>
      )}
    </div>
  );
}

function FinancialSection({ client }: { client: Client }) {
  const hasFinancial =
    client.net_worth_range ||
    client.risk_profile ||
    client.total_aum != null ||
    client.annual_revenue != null;

  if (!hasFinancial) return null;

  return (
    <div className="px-4">
      <SectionTitle>Financial</SectionTitle>
      <MobileCard>
        <div className="grid grid-cols-2 gap-y-3 gap-x-4">
          {client.net_worth_range && (
            <div>
              <p
                className="text-[11px] uppercase tracking-wider font-medium"
                style={{ color: "var(--text-muted)" }}
              >
                Net Worth Range
              </p>
              <p
                className="text-sm mt-0.5"
                style={{ color: "var(--text-primary)" }}
              >
                {client.net_worth_range}
              </p>
            </div>
          )}
          {client.risk_profile && (
            <div>
              <p
                className="text-[11px] uppercase tracking-wider font-medium"
                style={{ color: "var(--text-muted)" }}
              >
                Risk Profile
              </p>
              <p
                className="text-sm mt-0.5"
                style={{ color: "var(--text-primary)" }}
              >
                {client.risk_profile}
              </p>
            </div>
          )}
          {client.total_aum != null && (
            <div>
              <p
                className="text-[11px] uppercase tracking-wider font-medium flex items-center gap-1"
                style={{ color: "var(--text-muted)" }}
              >
                <DollarSign size={10} />
                Total AUM
              </p>
              <p
                className="text-sm mt-0.5 font-semibold"
                style={{ color: "var(--text-primary)" }}
              >
                {formatCurrency(client.total_aum)}
              </p>
            </div>
          )}
          {client.annual_revenue != null && (
            <div>
              <p
                className="text-[11px] uppercase tracking-wider font-medium flex items-center gap-1"
                style={{ color: "var(--text-muted)" }}
              >
                <DollarSign size={10} />
                Annual Revenue
              </p>
              <p
                className="text-sm mt-0.5 font-semibold"
                style={{ color: "var(--text-primary)" }}
              >
                {formatCurrency(client.annual_revenue)}
              </p>
            </div>
          )}
        </div>
      </MobileCard>
    </div>
  );
}

function ComplianceSection({ client }: { client: Client }) {
  const hasCompliance =
    client.kyc_completed != null || client.compliance_status;

  if (!hasCompliance) return null;

  return (
    <div className="px-4">
      <SectionTitle>Compliance</SectionTitle>
      <MobileCard>
        <div className="flex items-center gap-4">
          {client.kyc_completed != null && (
            <div className="flex items-center gap-2">
              {client.kyc_completed ? (
                <ShieldCheck size={16} style={{ color: "var(--success)" }} />
              ) : (
                <Shield size={16} style={{ color: "var(--warning)" }} />
              )}
              <div>
                <p
                  className="text-[11px] uppercase tracking-wider font-medium"
                  style={{ color: "var(--text-muted)" }}
                >
                  KYC
                </p>
                <p
                  className="text-sm"
                  style={{ color: "var(--text-primary)" }}
                >
                  {client.kyc_completed ? "Completed" : "Pending"}
                </p>
              </div>
            </div>
          )}
          {client.compliance_status && (
            <div>
              <p
                className="text-[11px] uppercase tracking-wider font-medium"
                style={{ color: "var(--text-muted)" }}
              >
                Compliance
              </p>
              <Badge
                variant={
                  client.compliance_status.toLowerCase() === "approved"
                    ? "success"
                    : client.compliance_status.toLowerCase() === "pending"
                    ? "warning"
                    : "default"
                }
              >
                {client.compliance_status}
              </Badge>
            </div>
          )}
        </div>
      </MobileCard>
    </div>
  );
}

function MetaSection({ client }: { client: Client }) {
  return (
    <div className="px-4">
      <MobileCard>
        <div className="grid grid-cols-2 gap-y-3 gap-x-4">
          <div>
            <p
              className="text-[11px] uppercase tracking-wider font-medium"
              style={{ color: "var(--text-muted)" }}
            >
              Created
            </p>
            <p
              className="text-sm mt-0.5"
              style={{ color: "var(--text-primary)" }}
            >
              {formatDate(client.created_at)}
            </p>
          </div>
          {client.updated_at && (
            <div>
              <p
                className="text-[11px] uppercase tracking-wider font-medium"
                style={{ color: "var(--text-muted)" }}
              >
                Last Updated
              </p>
              <p
                className="text-sm mt-0.5"
                style={{ color: "var(--text-primary)" }}
              >
                {formatRelativeDate(client.updated_at)}
              </p>
            </div>
          )}
          {client.source && (
            <div>
              <p
                className="text-[11px] uppercase tracking-wider font-medium"
                style={{ color: "var(--text-muted)" }}
              >
                Source
              </p>
              <p
                className="text-sm mt-0.5"
                style={{ color: "var(--text-primary)" }}
              >
                {client.source}
              </p>
            </div>
          )}
          {client.referral_source && (
            <div>
              <p
                className="text-[11px] uppercase tracking-wider font-medium"
                style={{ color: "var(--text-muted)" }}
              >
                Referral
              </p>
              <p
                className="text-sm mt-0.5"
                style={{ color: "var(--text-primary)" }}
              >
                {client.referral_source}
              </p>
            </div>
          )}
        </div>
      </MobileCard>
    </div>
  );
}

function NotesSection({ notes }: { notes: string }) {
  return (
    <div className="px-4">
      <SectionTitle>Notes</SectionTitle>
      <MobileCard>
        <div className="flex items-start gap-2">
          <FileText
            size={14}
            className="mt-0.5 shrink-0"
            style={{ color: "var(--text-muted)" }}
          />
          <p
            className="text-sm leading-relaxed whitespace-pre-wrap"
            style={{ color: "var(--text-secondary)" }}
          >
            {notes}
          </p>
        </div>
      </MobileCard>
    </div>
  );
}

function TagsSection({ tags }: { tags: (string | number)[] }) {
  if (tags.length === 0) return null;

  return (
    <div className="px-4">
      <SectionTitle count={tags.length}>Tags</SectionTitle>
      <div className="flex flex-wrap gap-2">
        {tags.map((tag) => (
          <span
            key={tag}
            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium"
            style={{
              background: "var(--bg-muted)",
              color: "var(--text-secondary)",
              border: "1px solid var(--border-light)",
            }}
          >
            <TagIcon size={10} />
            {tag}
          </span>
        ))}
      </div>
    </div>
  );
}

function DealsSection({ deals }: { deals: Deal[] }) {
  if (deals.length === 0) {
    return (
      <div className="px-4">
        <SectionTitle count={0}>Deals</SectionTitle>
        <div className="flex flex-col items-center py-8">
          <Briefcase
            size={32}
            strokeWidth={1.2}
            style={{ color: "var(--text-muted)", opacity: 0.4 }}
          />
          <p className="text-xs mt-2" style={{ color: "var(--text-muted)" }}>
            No related deals
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="px-4">
      <SectionTitle count={deals.length}>Deals</SectionTitle>
      <MobileCard noPadding>
        {deals.map((deal, idx) => (
          <div
            key={deal.id}
            className="flex items-center gap-3 px-4 py-3"
            style={{
              borderBottom:
                idx < deals.length - 1
                  ? "1px solid var(--border-light)"
                  : "none",
            }}
          >
            <Briefcase
              size={16}
              className="shrink-0"
              style={{ color: "var(--text-secondary)" }}
            />
            <div className="flex-1 min-w-0">
              <p
                className="text-sm font-medium truncate"
                style={{ color: "var(--text-primary)" }}
              >
                {deal.name}
              </p>
              <div className="flex items-center gap-2 mt-0.5">
                <Badge variant="outline">{deal.stage}</Badge>
                {deal.deal_value != null && (
                  <span
                    className="text-[11px] font-semibold"
                    style={{ color: "var(--text-secondary)" }}
                  >
                    {formatCurrency(deal.deal_value)}
                  </span>
                )}
              </div>
            </div>
          </div>
        ))}
      </MobileCard>
    </div>
  );
}

function TasksSection({ tasks }: { tasks: Task[] }) {
  if (tasks.length === 0) {
    return (
      <div className="px-4">
        <SectionTitle count={0}>Tasks</SectionTitle>
        <div className="flex flex-col items-center py-8">
          <CheckSquare
            size={32}
            strokeWidth={1.2}
            style={{ color: "var(--text-muted)", opacity: 0.4 }}
          />
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
          const isDone = task.status === "completed" || !!task.completion_date;
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
                  {task.title}
                </p>
                <div className="flex items-center gap-2 mt-1">
                  {task.priority && (
                    <Badge variant="outline">{task.priority}</Badge>
                  )}
                  {task.due_date && (
                    <span
                      className="text-[11px] font-medium"
                      style={{
                        color: isOverdue
                          ? "var(--danger)"
                          : "var(--text-muted)",
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

      {/* Financial skeleton */}
      <div className="px-4 space-y-3">
        <Skeleton className="h-3 w-20" />
        <div className="card-mobile p-4 space-y-2">
          <Skeleton className="h-3.5 w-32" />
          <Skeleton className="h-3.5 w-28" />
        </div>
      </div>

      {/* Deals skeleton */}
      <div className="px-4 space-y-3">
        <Skeleton className="h-3 w-16" />
        <div className="card-mobile p-4 space-y-3">
          <div className="flex items-center gap-3">
            <Skeleton className="w-4 h-4" />
            <Skeleton className="h-3.5 w-48" />
          </div>
          <div className="flex items-center gap-3">
            <Skeleton className="w-4 h-4" />
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
      <User
        size={48}
        strokeWidth={1.2}
        style={{ color: "var(--text-muted)", opacity: 0.4 }}
      />
      <h3
        className="mt-4 text-base font-semibold"
        style={{ color: "var(--text-secondary)" }}
      >
        Contact Not Found
      </h3>
      <p
        className="mt-1.5 text-sm max-w-xs"
        style={{ color: "var(--text-muted)" }}
      >
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

  // ---- Client query ----
  const {
    data: client,
    isLoading: clientLoading,
    error: clientError,
  } = useQuery<Client>({
    queryKey: ["client", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("clients")
        .select("*")
        .eq("id", id!)
        .single();
      if (error) throw error;
      return data as Client;
    },
    enabled: !!id,
  });

  // ---- Related deals query ----
  const { data: deals = [] } = useQuery<Deal[]>({
    queryKey: ["client-deals", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("deals")
        .select("*")
        .eq("client_id", id!)
        .order("created_at", { ascending: false });
      if (error) throw error;
      return (data ?? []) as Deal[];
    },
    enabled: !!id,
  });

  // ---- Related tasks query ----
  const { data: tasks = [] } = useQuery<Task[]>({
    queryKey: ["client-tasks", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("tasks")
        .select("*")
        .eq("client_id", id!)
        .order("due_date");
      if (error) throw error;
      return (data ?? []) as Task[];
    },
    enabled: !!id,
  });

  // ---- Render ----

  if (clientLoading) {
    return (
      <div>
        <PageHeader title="Contact" back="/contacts" />
        <ContactDetailSkeleton />
      </div>
    );
  }

  if (clientError || !client) {
    return (
      <div>
        <PageHeader title="Contact" back="/contacts" />
        <ErrorState
          message={
            clientError instanceof Error
              ? clientError.message
              : "Could not load this contact. It may have been deleted."
          }
        />
      </div>
    );
  }

  return (
    <div className="pb-6">
      <PageHeader
        title={displayName(client)}
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
        <HeroSection client={client} />

        {/* Contact info: emails, phones, website, address */}
        <ContactInfoSection client={client} />

        {/* Financial: AUM, revenue, net worth, risk */}
        <FinancialSection client={client} />

        {/* Compliance: KYC, compliance status */}
        <ComplianceSection client={client} />

        {/* Meta: created, updated, source, referral */}
        <MetaSection client={client} />

        {/* Notes */}
        {client.notes && <NotesSection notes={client.notes} />}

        {/* Tags */}
        {client.tags && client.tags.length > 0 && (
          <TagsSection tags={client.tags} />
        )}

        {/* Related Deals */}
        <DealsSection deals={deals} />

        {/* Related Tasks */}
        <TasksSection tasks={tasks} />
      </div>
    </div>
  );
}
