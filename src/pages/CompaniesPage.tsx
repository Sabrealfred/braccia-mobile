import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Building2, ChevronRight, Users, Briefcase, MapPin } from "lucide-react";
import { supabase } from "../lib/supabase";
import { SearchBar } from "../components/ui/SearchBar";
import { FAB } from "../components/ui/FAB";
import { Badge } from "../components/ui/Badge";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import { Avatar } from "../components/ui/Avatar";
import { SectionTitle } from "../components/ui/MobileCard";
import type { Company } from "../types";

type BadgeVariant = "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline";

const sectorVariants: Record<string, BadgeVariant> = {
  "Technology": "info",
  "Finance": "gold",
  "Healthcare": "success",
  "Energy": "warning",
  "Real Estate": "danger",
  "Manufacturing": "default",
  "Retail": "outline",
  "Hospitality": "gold",
  "Food & Beverage": "success",
  "Transportation": "info",
};

function getSectorVariant(sector: string): BadgeVariant {
  return sectorVariants[sector] ?? "default";
}

function formatLocation(city?: string, country?: string): string | null {
  if (city && country) return `${city}, ${country}`;
  return city || country || null;
}

async function fetchCompanies(search: string): Promise<Company[]> {
  let query = supabase
    .from("companies")
    .select("*")
    .order("name");

  if (search.trim()) {
    query = query.ilike("name", `%${search.trim()}%`);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

interface SectorGroup {
  sector: string;
  companies: Company[];
}

function groupBySector(companies: Company[]): SectorGroup[] {
  const map = new Map<string, Company[]>();

  for (const company of companies) {
    const sector = company.sector || "Other";
    const existing = map.get(sector);
    if (existing) {
      existing.push(company);
    } else {
      map.set(sector, [company]);
    }
  }

  return Array.from(map.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([sector, companies]) => ({ sector, companies }));
}

export function CompaniesPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState("");

  const { data: companies, isLoading, error } = useQuery<Company[]>({
    queryKey: ["companies", search],
    queryFn: () => fetchCompanies(search),
    staleTime: 30_000,
  });

  const groups = useMemo(
    () => groupBySector(companies ?? []),
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
            <div key={group.sector}>
              <SectionTitle count={group.companies.length}>
                {group.sector}
              </SectionTitle>

              <div>
                {group.companies.map((company) => {
                  const location = formatLocation(company.city, company.country);

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
                        src={company.logo?.src}
                        size="lg"
                      />

                      {/* Content */}
                      <div className="flex-1 min-w-0">
                        {/* Name + sector */}
                        <div className="flex items-center gap-2">
                          <span
                            className="text-sm font-semibold truncate"
                            style={{ color: "var(--text-primary)" }}
                          >
                            {company.name}
                          </span>
                          {company.sector && (
                            <Badge
                              variant={getSectorVariant(company.sector)}
                              className="shrink-0"
                            >
                              {company.sector}
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
                          <div className="flex items-center gap-1">
                            <Users
                              size={12}
                              style={{ color: "var(--text-muted)" }}
                            />
                            <span
                              className="text-[11px]"
                              style={{ color: "var(--text-muted)" }}
                            >
                              {company.nb_contacts ?? 0}
                            </span>
                          </div>
                          <div className="flex items-center gap-1">
                            <Briefcase
                              size={12}
                              style={{ color: "var(--text-muted)" }}
                            />
                            <span
                              className="text-[11px]"
                              style={{ color: "var(--text-muted)" }}
                            >
                              {company.nb_deals ?? 0}
                            </span>
                          </div>
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
