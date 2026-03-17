import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  Shield,
  ShieldOff,
  Mail,
  ChevronRight,
  UserCog,
} from "lucide-react";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { Avatar } from "../components/ui/Avatar";
import { SearchBar } from "../components/ui/SearchBar";
import { Badge } from "../components/ui/Badge";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import { SectionTitle } from "../components/ui/MobileCard";
import type { Sale } from "../types";

async function fetchStaff(search: string): Promise<Sale[]> {
  let query = supabase
    .from("sales")
    .select("*")
    .order("first_name");

  if (search.trim()) {
    const q = search.trim();
    query = query.or(
      `first_name.ilike.%${q}%,last_name.ilike.%${q}%,email.ilike.%${q}%`
    );
  }

  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

export function StaffPage() {
  const [search, setSearch] = useState("");
  const navigate = useNavigate();
  const { sale: currentSale } = useAuth();

  const {
    data: staff,
    isLoading,
    isError,
    error,
  } = useQuery<Sale[]>({
    queryKey: ["staff", search],
    queryFn: () => fetchStaff(search),
  });

  const { active, disabled } = useMemo(() => {
    if (!staff) return { active: [], disabled: [] };
    return {
      active: staff.filter((s) => !s.disabled),
      disabled: staff.filter((s) => s.disabled),
    };
  }, [staff]);

  const totalCount = staff?.length ?? 0;

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
          Staff
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
        placeholder="Search staff..."
      />

      {/* Loading */}
      {isLoading && <ListSkeleton count={6} />}

      {/* Error */}
      {isError && (
        <EmptyState
          icon={UserCog}
          title="Failed to load staff"
          description={
            error instanceof Error
              ? error.message
              : "An unexpected error occurred. Pull down to retry."
          }
        />
      )}

      {/* Empty state */}
      {!isLoading && !isError && totalCount === 0 && (
        <EmptyState
          icon={UserCog}
          title={search ? "No matches found" : "No staff members yet"}
          description={
            search
              ? `No staff matching "${search}". Try a different search.`
              : "Staff members will appear here once added."
          }
        />
      )}

      {/* Staff list */}
      {!isLoading && !isError && totalCount > 0 && (
        <div className="flex flex-col">
          {/* Active section */}
          {active.length > 0 && (
            <div>
              <SectionTitle count={active.length}>Active</SectionTitle>
              <div>
                {active.map((member) => (
                  <StaffRow
                    key={member.id}
                    member={member}
                    isCurrentUser={member.id === currentSale?.id}
                    onTap={() => navigate(`/staff/${member.id}`)}
                  />
                ))}
              </div>
            </div>
          )}

          {/* Disabled section */}
          {disabled.length > 0 && (
            <div style={{ opacity: 0.6 }}>
              <SectionTitle count={disabled.length}>Disabled</SectionTitle>
              <div>
                {disabled.map((member) => (
                  <StaffRow
                    key={member.id}
                    member={member}
                    isCurrentUser={member.id === currentSale?.id}
                    onTap={() => navigate(`/staff/${member.id}`)}
                  />
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

/* ─── Staff row component ──────────────────────────────────── */

interface StaffRowProps {
  member: Sale;
  isCurrentUser: boolean;
  onTap: () => void;
}

function StaffRow({ member, isCurrentUser, onTap }: StaffRowProps) {
  return (
    <button
      onClick={onTap}
      className="flex items-center gap-3 w-full px-4 py-3 text-left transition-colors active:bg-[var(--bg-muted)]"
      style={{ borderBottom: "1px solid var(--border-light)" }}
    >
      {/* Avatar */}
      <Avatar
        firstName={member.first_name}
        lastName={member.last_name}
        src={member.avatar?.src}
        size="lg"
      />

      {/* Info block */}
      <div className="flex-1 min-w-0">
        {/* Name + badges row */}
        <div className="flex items-center gap-2 flex-wrap">
          <span
            className="text-sm font-semibold truncate"
            style={{ color: "var(--text-primary)" }}
          >
            {member.first_name} {member.last_name}
          </span>

          {isCurrentUser && (
            <Badge variant="gold">You</Badge>
          )}

          {member.administrator && (
            <Badge variant="info">
              <Shield size={9} />
              Admin
            </Badge>
          )}

          {member.disabled && (
            <Badge variant="warning">
              <ShieldOff size={9} />
              Disabled
            </Badge>
          )}
        </div>

        {/* Email */}
        {member.email && (
          <div className="flex items-center gap-1.5 mt-1">
            <Mail
              size={12}
              style={{ color: "var(--text-muted)", flexShrink: 0 }}
            />
            <span
              className="text-xs truncate"
              style={{ color: "var(--text-secondary)" }}
            >
              {member.email}
            </span>
          </div>
        )}
      </div>

      {/* Chevron */}
      <ChevronRight
        size={18}
        style={{ color: "var(--text-muted)", flexShrink: 0 }}
      />
    </button>
  );
}
