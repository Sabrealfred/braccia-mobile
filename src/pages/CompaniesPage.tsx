import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Building2, ChevronRight, Users, DollarSign, MapPin } from "lucide-react";
import { supabase } from "../lib/supabase";
import { SearchBar } from "../components/ui/SearchBar";
import { FAB } from "../components/ui/FAB";
import { Badge } from "../components/ui/Badge";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import { Avatar } from "../components/ui/Avatar";
import { SectionTitle } from "../components/ui/MobileCard";

type BadgeVariant = "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline";

interface ClientEntity {
  id: string;
  name: string;
  industry?: string;
  city?: string;
  country?: string;
  annual_revenue?: number;
  employee_count?: number;
  primary_phone?: string;
  primary_email?: string;
  website?: string;
  status?: string;
  created_at?: string;
}

const industryVariants: Record<string, BadgeVariant> = {
  "Technology": "info",
  "Finance": "gold",
  "Healthcare": "success",
  "Energy": "warning",
  "Real Estate": "danger",
  "Manufacturing": "default",
  "Legal": "outline",
  "Consulting": "gold",
  "Other": "default",
};

function getIndustryVariant(industry: string): BadgeVariant {
  return industryVariants[industry] ?? "default";
}

function formatLocation(city?: string, country?: string): string | null {
  if (city && country) return `${city}, ${country}`;
  return city || country || null;
}

function formatRevenue(amount?: number): string | null {
  if (!amount) return null;
  if (amount >= 1_000_000_000) return `$${(amount / 1_000_000_000).toFixed(1)}B`;
  if (amount >= 1_000_000) return `$${(amount / 1_000_000).toFixed(1)}M`;
  if (amount >= 1_000) return `$${(amount / 1_000).toFixed(0)}K`;
  return `$${amount}`;
}

async function fetchEntities(search: string): Promise<ClientEntity[]> {
  let query = supabase
    .from("clients")
    .select("*")
    .eq("client_type", "entity")
    .order("name");

  if (search.trim()) {
    query = query.ilike("name", `%${search.trim()}%`);
  }

  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []) as ClientEntity[];
}

interface IndustryGroup {
  industry: string;
  companies: ClientEntity[];
}

function groupByIndustry(companies: ClientEntity[]): IndustryGroup[] {
  const map = new Map<string, ClientEntity[]>();

  for (const company of companies) {
    const industry = company.industry || "Other";
    const existing = map.get(industry);
    if (existing) {
      existing.push(company);
    } else {
      map.set(industry, [company]);
    }
  }

  return Array.from(map.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([industry, companies]) => ({ industry, companies }));
}

export function CompaniesPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState("");

  const { data: companies, isLoading, error } = useQuery<ClientEntity[]>({
    queryKey: ["companies", search],
    queryFn: () => fetchEntities(search),
    staleTime: 30_000,
  });

  const groups = useMemo(
    () => groupByIndustry(companies ?? []),
    [companies],
  );

  const totalCount = companies?.length ?? 0;

  return (
    <div
      className="min-h-screen pb-32"
      style={{ background: "var(--bg-primary)" }}
    >
      {/* Header */}
      <div className="px-4 pt-3 pb-1">
        <h1
          className="text-lg font-bold"
          style={{ color: "var(--text-primary)" }}
        >
          Companies
        </h1>
        {!isLoading && !error && (
          <p className="text-xs" style={{ color: "var(--text-muted)" }}>
            {totalCount} {totalCount === 1 ? "company" : "companies"}
          </p>
        )}
      </div>

      {/* Search */}
      <SearchBar
        value={search}
        onChange={setSearch}
        placeholder="Search companies..."
      />

      {/* Loading */}
      {isLoading && <ListSkeleton count={6} />}

      {/* Error */}
      {error && (
        <div className="px-4 py-8 text-center">
          <p className="text-sm" style={{ color: "var(--danger)" }}>
            Failed to load companies. Pull down to retry.
          </p>
        </div>
      )}

      {/* Empty state */}
      {!isLoading && !error && totalCount === 0 && (
        <EmptyState
          icon={Building2}
          title={search ? "No companies found" : "No companies yet"}
          description={
            search
              ? `No results for "${search}". Try a different search.`
              : "Create your first company to get started."
          }
        />
      )}

      {/* Grouped list */}
      {!isLoading && !error && totalCount > 0 && (
        <div>
          {groups.map((group) => (
            <div key={group.industry}>
              <SectionTitle count={group.companies.length}>
                {group.industry}
              </SectionTitle>

              <div>
                {group.companies.map((company) => {
                  const location = formatLocation(company.city, company.country);
                  const revenue = formatRevenue(company.annual_revenue);

                  return (
                    <button
                      key={company.id}
                      onClick={() => navigate(`/companies/${company.id}`)}
                      className="w-full flex items-center gap-3 px-4 py-3 active:bg-[var(--bg-muted)] transition-colors text-left"
                      style={{
                        borderBottom: "1px solid var(--border-light)",
                      }}
                    >
                      {/* Avatar */}
                      <Avatar
                        firstName={company.name}
                        lastName=""
                        size="lg"
                      />

                      {/* Content */}
                      <div className="flex-1 min-w-0">
                        {/* Name + industry */}
                        <div className="flex items-center gap-2">
                          <span
                            className="text-sm font-semibold truncate"
                            style={{ color: "var(--text-primary)" }}
                          >
                            {company.name}
                          </span>
                          {company.industry && (
                            <Badge
                              variant={getIndustryVariant(company.industry)}
                              className="shrink-0"
                            >
                              {company.industry}
                            </Badge>
                          )}
                        </div>

                        {/* Location */}
                        {location && (
                          <div className="flex items-center gap-1 mt-0.5">
                            <MapPin
                              size={12}
                              style={{ color: "var(--text-muted)" }}
                              className="shrink-0"
                            />
                            <span
                              className="text-xs truncate"
                              style={{ color: "var(--text-secondary)" }}
                            >
                              {location}
                            </span>
                          </div>
                        )}

                        {/* Stats row */}
                        <div className="flex items-center gap-3 mt-1">
                          {revenue && (
                            <div className="flex items-center gap-1">
                              <DollarSign
                                size={12}
                                style={{ color: "var(--text-muted)" }}
                              />
                              <span
                                className="text-[11px]"
                                style={{ color: "var(--text-muted)" }}
                              >
                                {revenue}
                              </span>
                            </div>
                          )}
                          {company.employee_count != null && company.employee_count > 0 && (
                            <div className="flex items-center gap-1">
                              <Users
                                size={12}
                                style={{ color: "var(--text-muted)" }}
                              />
                              <span
                                className="text-[11px]"
                                style={{ color: "var(--text-muted)" }}
                              >
                                {company.employee_count}
                              </span>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Chevron */}
                      <ChevronRight
                        size={18}
                        style={{ color: "var(--text-muted)" }}
                        className="shrink-0"
                      />
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* FAB */}
      <FAB to="/companies/create" label="Company" />
    </div>
  );
}
