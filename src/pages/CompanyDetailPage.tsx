import { useParams, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  Globe,
  Phone,
  MapPin,
  DollarSign,
  FileText,
  Users,
  Briefcase,
  ChevronRight,
  ExternalLink,
  Building2,
  Calendar,
  Shield,
  Mail,
} from "lucide-react";
import { supabase } from "../lib/supabase";
import { formatCurrency, formatDate } from "../lib/utils";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard, SectionTitle } from "../components/ui/MobileCard";
import { Badge } from "../components/ui/Badge";
import { Skeleton, CardSkeleton } from "../components/ui/Skeleton";
import { EmptyState } from "../components/ui/EmptyState";
import type { Deal } from "../types";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ClientEntity {
  id: string;
  name: string;
  full_name?: string;
  client_type?: string;
  status?: string;
  industry?: string;
  website?: string;
  primary_phone?: string;
  primary_email?: string;
  address_line1?: string;
  city?: string;
  state?: string;
  postal_code?: string;
  country?: string;
  tax_id?: string;
  annual_revenue?: number;
  employee_count?: number;
  incorporation_country?: string;
  incorporation_date?: string;
  notes?: string;
  compliance_status?: string;
  kyc_status?: string;
  created_at?: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const statusBadgeVariant: Record<string, "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline"> = {
  prospect: "outline",
  active: "success",
  inactive: "warning",
  archived: "danger",
};

const stageBadgeVariant: Record<string, "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline"> = {
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

function formatRevenue(amount?: number): string | null {
  if (!amount) return null;
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

// ---------------------------------------------------------------------------
// Data hooks
// ---------------------------------------------------------------------------

function useCompany(id: string | undefined) {
  return useQuery<ClientEntity>({
    queryKey: ["company", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("clients")
        .select("*")
        .eq("id", id!)
        .single();
      if (error) throw error;
      return data as ClientEntity;
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
        .eq("client_id", id!);
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
  const { data: deals = [], isLoading: dealsLoading } = useCompanyDeals(id);

  // Build address string
  const addressParts = [
    company?.address_line1,
    company?.city,
    company?.state,
    company?.postal_code,
    company?.country,
  ].filter(Boolean);
  const fullAddress = addressParts.length > 0 ? addressParts.join(", ") : null;

  // Ensure website has protocol for href
  const websiteHref = company?.website
    ? company.website.startsWith("http")
      ? company.website
      : `https://${company.website}`
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
          {/* Large avatar */}
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

          {/* Name */}
          <h2
            className="font-serif text-xl text-center leading-tight mt-1"
            style={{ color: "var(--text-primary)" }}
          >
            {company.name}
          </h2>

          {/* Badges */}
          <div className="flex items-center gap-2 flex-wrap justify-center">
            {company.industry && (
              <Badge variant="gold">{company.industry}</Badge>
            )}
            {company.client_type && (
              <Badge variant="outline">
                {company.client_type === "entity" ? "Entity" : "Individual"}
              </Badge>
            )}
            {company.status && (
              <Badge variant={statusBadgeVariant[company.status] ?? "default"}>
                {company.status.charAt(0).toUpperCase() + company.status.slice(1)}
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
            {company.website && company.primary_phone && <Divider />}

            <InfoRow
              icon={Phone}
              label="Phone"
              value={company.primary_phone}
              href={company.primary_phone ? `tel:${company.primary_phone}` : undefined}
            />
            {company.primary_phone && company.primary_email && <Divider />}

            <InfoRow
              icon={Mail}
              label="Email"
              value={company.primary_email}
              href={company.primary_email ? `mailto:${company.primary_email}` : undefined}
            />
            {company.primary_email && fullAddress && <Divider />}

            <InfoRow
              icon={MapPin}
              label="Address"
              value={fullAddress}
            />
            {fullAddress && company.tax_id && <Divider />}

            <InfoRow
              icon={FileText}
              label="Tax ID"
              value={company.tax_id}
            />
            {company.tax_id && formatRevenue(company.annual_revenue) && <Divider />}

            <InfoRow
              icon={DollarSign}
              label="Annual Revenue"
              value={formatRevenue(company.annual_revenue)}
            />
            {formatRevenue(company.annual_revenue) && company.employee_count && <Divider />}

            <InfoRow
              icon={Users}
              label="Employees"
              value={company.employee_count ? String(company.employee_count) : null}
            />
            {company.employee_count && company.incorporation_country && <Divider />}

            <InfoRow
              icon={MapPin}
              label="Incorporation Country"
              value={company.incorporation_country}
            />
            {company.incorporation_country && company.incorporation_date && <Divider />}

            <InfoRow
              icon={Calendar}
              label="Incorporation Date"
              value={company.incorporation_date ? formatDate(company.incorporation_date) : null}
            />

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

      {/* Notes section */}
      {company?.notes && (
        <div className="px-4 mb-3">
          <SectionTitle>Notes</SectionTitle>
          <MobileCard>
            <p
              className="text-sm leading-relaxed"
              style={{ color: "var(--text-secondary)" }}
            >
              {company.notes}
            </p>
          </MobileCard>
        </div>
      )}

      {/* Compliance & KYC */}
      {(company?.compliance_status || company?.kyc_status) && (
        <div className="px-4 mb-3">
          <SectionTitle>Compliance</SectionTitle>
          <MobileCard>
            {company.compliance_status && (
              <div className="flex items-center gap-3 py-2.5">
                <Shield
                  size={16}
                  className="shrink-0"
                  style={{ color: "var(--text-muted)" }}
                />
                <div className="flex-1">
                  <p
                    className="text-[11px] font-medium uppercase tracking-wider mb-0.5"
                    style={{ color: "var(--text-muted)" }}
                  >
                    Compliance Status
                  </p>
                  <Badge
                    variant={
                      company.compliance_status === "compliant"
                        ? "success"
                        : company.compliance_status === "pending"
                          ? "warning"
                          : "danger"
                    }
                  >
                    {company.compliance_status.charAt(0).toUpperCase() +
                      company.compliance_status.slice(1)}
                  </Badge>
                </div>
              </div>
            )}
            {company.compliance_status && company.kyc_status && <Divider />}
            {company.kyc_status && (
              <div className="flex items-center gap-3 py-2.5">
                <FileText
                  size={16}
                  className="shrink-0"
                  style={{ color: "var(--text-muted)" }}
                />
                <div className="flex-1">
                  <p
                    className="text-[11px] font-medium uppercase tracking-wider mb-0.5"
                    style={{ color: "var(--text-muted)" }}
                  >
                    KYC Status
                  </p>
                  <Badge
                    variant={
                      company.kyc_status === "verified"
                        ? "success"
                        : company.kyc_status === "pending"
                          ? "warning"
                          : "danger"
                    }
                  >
                    {company.kyc_status.charAt(0).toUpperCase() +
                      company.kyc_status.slice(1)}
                  </Badge>
                </div>
              </div>
            )}
          </MobileCard>
        </div>
      )}

      {/* Deals section */}
      <div className="px-4 mb-3">
        <SectionTitle count={deals.length}>Deals</SectionTitle>
        {dealsLoading ? (
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
                      {(deal.amount ?? deal.deal_value ?? 0) > 0 && (
                        <span
                          className="text-xs font-medium"
                          style={{ color: "var(--text-secondary)" }}
                        >
                          {formatCurrency(deal.amount ?? deal.deal_value ?? 0)}
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
