import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  Globe,
  Phone,
  MapPin,
  Linkedin,
  DollarSign,
  FileText,
  Users,
  Briefcase,
  ChevronRight,
  ExternalLink,
  Building2,
} from "lucide-react";
import { supabase } from "../lib/supabase";
import { formatCurrency, formatDate } from "../lib/utils";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Avatar } from "../components/ui/Avatar";
import { Badge } from "../components/ui/Badge";
import { Skeleton, CardSkeleton } from "../components/ui/Skeleton";
import { EmptyState } from "../components/ui/EmptyState";
import type { Company, Contact, Deal } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const sizeLabels: Record<number, string> = {
  1: "1-9",
  10: "10-49",
  50: "50-249",
  250: "250-499",
  500: "500+",
};

function getSizeLabel(size: number): string {
  return sizeLabels[size] ?? `${size}`;
}

const stageBadgeVariant: Record<string, "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline"> = {
  opportunity: "info",
  "proposal-sent": "warning",
  "in-negociation": "gold",
  won: "success",
  lost: "danger",
  sourcing: "default",
  nda: "outline",
  dd: "info",
  negotiation: "gold",
  legal: "warning",
  closed_won: "success",
  closed_lost: "danger",
};

function stageVariant(stage: string) {
  return stageBadgeVariant[stage] ?? "default";
}

function stageLabel(stage: string): string {
  return stage
    .replace(/[-_]/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

// ---------------------------------------------------------------------------
// Data hooks
// ---------------------------------------------------------------------------

function useCompany(id: string | undefined) {
  return useQuery<Company>({
    queryKey: ["company", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("companies")
        .select("*")
        .eq("id", Number(id))
        .single();
      if (error) throw error;
      return data as Company;
    },
    enabled: !!id,
  });
}

function useCompanyContacts(id: string | undefined) {
  return useQuery<Contact[]>({
    queryKey: ["company-contacts", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("contacts")
        .select("*")
        .eq("company_id", Number(id));
      if (error) throw error;
      return (data ?? []) as Contact[];
    },
    enabled: !!id,
  });
}

function useCompanyDeals(id: string | undefined) {
  return useQuery<Deal[]>({
    queryKey: ["company-deals", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("deals")
        .select("*")
        .eq("company_id", Number(id));
      if (error) throw error;
      return (data ?? []) as Deal[];
    },
    enabled: !!id,
  });
}

// ---------------------------------------------------------------------------
// Skeleton states
// ---------------------------------------------------------------------------

function HeroSkeleton() {
  return (
    <div className="flex flex-col items-center gap-3 px-4 py-6">
      <Skeleton className="w-20 h-20 rounded-full" />
      <Skeleton className="h-6 w-48" />
      <div className="flex gap-2">
        <Skeleton className="h-5 w-20 rounded-full" />
        <Skeleton className="h-5 w-16 rounded-full" />
      </div>
    </div>
  );
}

function ContactListSkeleton() {
  return (
    <div className="space-y-0">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="flex items-center gap-3 px-4 py-3">
          <Skeleton className="w-10 h-10 rounded-full" />
          <div className="flex-1 space-y-1.5">
            <Skeleton className="h-4 w-32" />
            <Skeleton className="h-3 w-48" />
          </div>
        </div>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

function InfoRow({
  icon: Icon,
  label,
  value,
  href,
  external,
}: {
  icon: typeof Globe;
  label: string;
  value: string | undefined | null;
  href?: string;
  external?: boolean;
}) {
  if (!value) return null;

  const content = (
    <div className="flex items-start gap-3 py-2.5">
      <Icon
        size={16}
        className="shrink-0 mt-0.5"
        style={{ color: "var(--text-muted)" }}
      />
      <div className="flex-1 min-w-0">
        <p
          className="text-[11px] font-medium uppercase tracking-wider mb-0.5"
          style={{ color: "var(--text-muted)" }}
        >
          {label}
        </p>
        <p
          className="text-sm leading-snug break-words"
          style={{ color: href ? "var(--text-gold)" : "var(--text-primary)" }}
        >
          {value}
        </p>
      </div>
      {external && (
        <ExternalLink
          size={14}
          className="shrink-0 mt-1"
          style={{ color: "var(--text-muted)" }}
        />
      )}
    </div>
  );

  if (href) {
    return (
      <a
        href={href}
        target={external ? "_blank" : undefined}
        rel={external ? "noopener noreferrer" : undefined}
        className="block active:opacity-70 transition-opacity"
      >
        {content}
      </a>
    );
  }

  return content;
}

function Divider() {
  return (
    <div
      className="h-px ml-7"
      style={{ background: "var(--border-light)" }}
    />
  );
}

// ---------------------------------------------------------------------------
// Main component
// ---------------------------------------------------------------------------

export function CompanyDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const { data: company, isLoading, isError } = useCompany(id);
  const { data: contacts = [], isLoading: contactsLoading } = useCompanyContacts(id);
  const { data: deals = [], isLoading: dealsLoading } = useCompanyDeals(id);

  // Build address string
  const addressParts = [
    company?.address,
    company?.city,
    company?.stateAbbr,
    company?.zipcode,
    company?.country,
  ].filter(Boolean);
  const fullAddress = addressParts.length > 0 ? addressParts.join(", ") : null;

  // Ensure website has protocol for href
  const websiteHref = company?.website
    ? company.website.startsWith("http")
      ? company.website
      : `https://${company.website}`
    : undefined;

  // LinkedIn URL
  const linkedinHref = company?.linkedin_url
    ? company.linkedin_url.startsWith("http")
      ? company.linkedin_url
      : `https://${company.linkedin_url}`
    : undefined;

  // Error state
  if (isError) {
    return (
      <div className="safe-bottom" style={{ background: "var(--bg-primary)" }}>
        <PageHeader title="Company" back />
        <EmptyState
          icon={Building2}
          title="Company not found"
          description="This company may have been deleted or you don't have access."
        />
      </div>
    );
  }

  return (
    <div className="safe-bottom" style={{ background: "var(--bg-secondary)" }}>
      {/* Header */}
      <PageHeader
        title={company?.name ?? "Company"}
        back
      />

      {/* Hero */}
      {isLoading ? (
        <HeroSkeleton />
      ) : company ? (
        <div className="flex flex-col items-center gap-2 px-4 pt-2 pb-5">
          {/* Large avatar / logo */}
          {company.logo?.src ? (
            <img
              src={company.logo.src}
              alt={company.name}
              className="w-20 h-20 rounded-full object-cover border-2"
              style={{ borderColor: "var(--border-light)" }}
            />
          ) : (
            <div
              className="w-20 h-20 rounded-full flex items-center justify-center"
              style={{ background: "var(--gold)" }}
            >
              <span
                className="font-serif text-2xl"
                style={{ color: "var(--white)" }}
              >
                {company.name
                  .split(/\s+/)
                  .slice(0, 2)
                  .map((w) => w[0])
                  .join("")
                  .toUpperCase()}
              </span>
            </div>
          )}

          {/* Name */}
          <h2
            className="font-serif text-xl text-center leading-tight mt-1"
            style={{ color: "var(--text-primary)" }}
          >
            {company.name}
          </h2>

          {/* Badges */}
          <div className="flex items-center gap-2 flex-wrap justify-center">
            {company.sector && (
              <Badge variant="gold">{company.sector}</Badge>
            )}
            {company.size && (
              <Badge variant="outline">
                {getSizeLabel(company.size)} employees
              </Badge>
            )}
          </div>
        </div>
      ) : null}

      {/* Info section */}
      <div className="px-4 mb-3">
        <SectionTitle>Company Info</SectionTitle>
        {isLoading ? (
          <CardSkeleton />
        ) : company ? (
          <MobileCard>
            <InfoRow
              icon={Globe}
              label="Website"
              value={company.website}
              href={websiteHref}
              external
            />
            {company.website && company.phone_number && <Divider />}

            <InfoRow
              icon={Phone}
              label="Phone"
              value={company.phone_number}
              href={company.phone_number ? `tel:${company.phone_number}` : undefined}
            />
            {company.phone_number && fullAddress && <Divider />}

            <InfoRow
              icon={MapPin}
              label="Address"
              value={fullAddress}
            />
            {fullAddress && company.linkedin_url && <Divider />}

            <InfoRow
              icon={Linkedin}
              label="LinkedIn"
              value={company.linkedin_url ? "View Profile" : undefined}
              href={linkedinHref}
              external
            />
            {company.linkedin_url && company.revenue && <Divider />}

            <InfoRow
              icon={DollarSign}
              label="Revenue"
              value={company.revenue}
            />
            {company.revenue && company.tax_identifier && <Divider />}

            <InfoRow
              icon={FileText}
              label="Tax ID"
              value={company.tax_identifier}
            />
            {company.tax_identifier && company.description && <Divider />}

            {company.description && (
              <div className="py-2.5">
                <p
                  className="text-[11px] font-medium uppercase tracking-wider mb-1"
                  style={{ color: "var(--text-muted)" }}
                >
                  Description
                </p>
                <p
                  className="text-sm leading-relaxed"
                  style={{ color: "var(--text-secondary)" }}
                >
                  {company.description}
                </p>
              </div>
            )}

            {/* Created at */}
            {company.created_at && (
              <>
                <Divider />
                <div className="py-2.5">
                  <p
                    className="text-[11px] font-medium uppercase tracking-wider"
                    style={{ color: "var(--text-muted)" }}
                  >
                    Added {formatDate(company.created_at)}
                  </p>
                </div>
              </>
            )}
          </MobileCard>
        ) : null}
      </div>

      {/* Contacts section */}
      <div className="px-4 mb-3">
        <SectionTitle count={contacts.length}>Contacts</SectionTitle>
        {contactsLoading ? (
          <ContactListSkeleton />
        ) : contacts.length === 0 ? (
          <MobileCard>
            <div className="py-6 text-center">
              <Users
                size={32}
                strokeWidth={1.2}
                style={{ color: "var(--text-muted)", opacity: 0.4, margin: "0 auto" }}
              />
              <p
                className="text-sm mt-2"
                style={{ color: "var(--text-muted)" }}
              >
                No contacts yet
              </p>
            </div>
          </MobileCard>
        ) : (
          <MobileCard noPadding>
            {contacts.map((contact, idx) => (
              <div key={contact.id}>
                <button
                  onClick={() => navigate(`/contacts/${contact.id}`)}
                  className="flex items-center gap-3 w-full px-4 py-3 text-left active:bg-[var(--bg-muted)] transition-colors"
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
                        className="text-xs truncate"
                        style={{ color: "var(--text-muted)" }}
                      >
                        {contact.title}
                      </p>
                    )}
                  </div>
                  <ChevronRight
                    size={16}
                    style={{ color: "var(--text-muted)" }}
                  />
                </button>
                {idx < contacts.length - 1 && (
                  <div
                    className="h-px ml-16"
                    style={{ background: "var(--border-light)" }}
                  />
                )}
              </div>
            ))}
          </MobileCard>
        )}
      </div>

      {/* Deals section */}
      <div className="px-4 mb-3">
        <SectionTitle count={deals.length}>Deals</SectionTitle>
        {dealsLoading ? (
          <ContactListSkeleton />
        ) : deals.length === 0 ? (
          <MobileCard>
            <div className="py-6 text-center">
              <Briefcase
                size={32}
                strokeWidth={1.2}
                style={{ color: "var(--text-muted)", opacity: 0.4, margin: "0 auto" }}
              />
              <p
                className="text-sm mt-2"
                style={{ color: "var(--text-muted)" }}
              >
                No deals yet
              </p>
            </div>
          </MobileCard>
        ) : (
          <MobileCard noPadding>
            {deals.map((deal, idx) => (
              <div key={deal.id}>
                <button
                  onClick={() => navigate(`/deals/${deal.id}`)}
                  className="flex items-center gap-3 w-full px-4 py-3 text-left active:bg-[var(--bg-muted)] transition-colors"
                >
                  <div
                    className="w-10 h-10 rounded-full flex items-center justify-center shrink-0"
                    style={{ background: "var(--bg-muted)" }}
                  >
                    <Briefcase
                      size={18}
                      style={{ color: "var(--text-gold)" }}
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p
                      className="text-sm font-semibold truncate"
                      style={{ color: "var(--text-primary)" }}
                    >
                      {deal.name}
                    </p>
                    <div className="flex items-center gap-2 mt-0.5">
                      <Badge variant={stageVariant(deal.stage)}>
                        {stageLabel(deal.stage)}
                      </Badge>
                      {deal.amount > 0 && (
                        <span
                          className="text-xs font-medium"
                          style={{ color: "var(--text-secondary)" }}
                        >
                          {formatCurrency(deal.amount)}
                        </span>
                      )}
                    </div>
                  </div>
                  <ChevronRight
                    size={16}
                    style={{ color: "var(--text-muted)" }}
                  />
                </button>
                {idx < deals.length - 1 && (
                  <div
                    className="h-px ml-16"
                    style={{ background: "var(--border-light)" }}
                  />
                )}
              </div>
            ))}
          </MobileCard>
        )}
      </div>
    </div>
  );
}
