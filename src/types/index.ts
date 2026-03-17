// ============================================================
// Braccia Mobile CRM — Shared Types
// Matches matwal-premium Supabase schema
// With backward-compat fields so existing pages compile
// ============================================================

// ── Staff / User Profile ────────────────────────────────────

export interface UserProfile {
  id: string; // UUID — same as auth.users.id
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  role: string;
  avatar_url: string | null;
  is_active: boolean;
  phone: string | null;
  permissions: Record<string, unknown> | null;
  preferences: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
  last_login_at: string | null;
  last_active_at: string | null;
  two_factor_enabled: boolean;
  metadata: Record<string, unknown> | null;
  family_id: string | null;
  // -- backward-compat (legacy pages read these) --
  /** @deprecated Use avatar_url */
  avatar?: RAFile;
  /** @deprecated Use role === 'admin' */
  administrator?: boolean;
  /** @deprecated Use !is_active */
  disabled?: boolean;
}

export interface StaffUser {
  id: string; // UUID
  user_id: string; // UUID -> auth.users
  email: string;
  full_name: string;
  first_name?: string;
  last_name?: string;
  role: string;
  department: string | null;
  phone: string | null;
  avatar_url: string | null;
  is_active: boolean;
  permissions: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
  organization_id: string | null;
  last_login_at: string | null;
  // -- backward-compat --
  /** @deprecated Use avatar_url */
  avatar?: RAFile;
  /** @deprecated Use role === 'admin' */
  administrator?: boolean;
  /** @deprecated Use !is_active */
  disabled?: boolean;
}

/**
 * Backward-compatible alias.
 * `import type { Sale }` keeps compiling.
 */
export type Sale = StaffUser;

// ── Client (replaces Contact + Company) ─────────────────────

export interface Client {
  id: string; // UUID
  name: string;
  full_name: string | null;
  display_name: string | null;
  email: string | null;
  primary_email: string | null;
  secondary_email: string | null;
  phone: string | null;
  primary_phone: string | null;
  secondary_phone: string | null;
  client_type: "individual" | "entity";
  status: "prospect" | "active" | "inactive" | "archived";
  company: string | null;
  industry: string | null;
  website: string | null;
  address_line1: string | null;
  address_line2: string | null;
  city: string | null;
  state: string | null;
  postal_code: string | null;
  country: string | null;
  tax_id: string | null;
  net_worth_range: string | null;
  risk_profile: string | null;
  source: string | null;
  referral_source: string | null;
  notes: string | null;
  tags: string[] | null;
  assigned_consultant: string | null; // UUID
  account_manager: string | null;
  total_aum: number | null;
  annual_revenue: number | null;
  employee_count: number | null;
  estimated_net_worth: number | null;
  kyc_completed: boolean | null;
  compliance_status: string | null;
  organization_id: string | null;
  created_at: string;
  updated_at: string;
  // -- backward-compat fields (legacy Contact/Company pages) --
  /** @deprecated Use full_name or name */
  first_name?: string;
  /** @deprecated Use full_name or name */
  last_name?: string;
  /** @deprecated */
  title?: string;
  /** @deprecated Use client_id on deals */
  company_id?: number | string;
  /** @deprecated Use email */
  email_jsonb?: EmailAndType[];
  /** @deprecated Use avatar_url when available */
  avatar?: Partial<RAFile>;
  /** @deprecated */
  linkedin_url?: string;
  /** @deprecated Use created_at */
  first_seen?: string;
  /** @deprecated Use updated_at */
  last_seen?: string;
  /** @deprecated */
  has_newsletter?: boolean;
  /** @deprecated */
  gender?: string;
  /** @deprecated Use assigned_consultant */
  sales_id?: number | string;
  /** @deprecated Use notes */
  background?: string;
  /** @deprecated Use phone */
  phone_jsonb?: PhoneNumberAndType[];
  /** @deprecated */
  nb_tasks?: number;
  /** @deprecated */
  company_name?: string;
  // -- backward-compat Company fields --
  /** @deprecated Use avatar_url */
  logo?: RAFile;
  /** @deprecated Use industry */
  sector?: string;
  /** @deprecated Use employee_count */
  size?: number;
  /** @deprecated Use phone */
  phone_number?: string;
  /** @deprecated Use address_line1 */
  address?: string;
  /** @deprecated Use postal_code */
  zipcode?: string;
  /** @deprecated Use state */
  stateAbbr?: string;
  /** @deprecated Use notes */
  description?: string;
  /** @deprecated Use annual_revenue */
  revenue?: string;
  /** @deprecated Use tax_id */
  tax_identifier?: string;
  /** @deprecated */
  context_links?: string[];
  /** @deprecated */
  nb_contacts?: number;
  /** @deprecated */
  nb_deals?: number;
}

/** Backward-compat alias -- pages importing Contact keep compiling. */
export type Contact = Client;

/**
 * No separate companies table in matwal-premium.
 * Clients with client_type='entity' serve as companies.
 */
export type Company = Client;

// ── Deal ────────────────────────────────────────────────────

export interface Deal {
  id: string; // UUID
  name: string;
  client_id: string | null; // UUID -> clients
  stage: string;
  status: string | null;
  deal_type: string | null;
  deal_value: number | null;
  currency: string | null;
  description: string | null;
  priority: string | null;
  probability: number | null;
  probability_percentage: number | null;
  expected_close_date: string | null;
  actual_close_date: string | null;
  closing_date: string | null;
  target_company: string | null;
  buyer_name: string | null;
  seller_name: string | null;
  enterprise_value: number | null;
  equity_value: number | null;
  strategic_rationale: string | null;
  risk_level: string | null;
  lead_consultant: string | null; // UUID
  owner_id: string | null; // UUID
  created_by: string | null; // UUID
  organization_id: string | null;
  tags: string[] | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
  is_active: boolean | null;
  is_confidential: boolean | null;
  // -- extended deal fields (used in DealDetailPage) --
  dd_start_date?: string | null;
  dd_end_date?: string | null;
  loi_signed_date?: string | null;
  expected_revenue?: number | null;
  lost_reason?: string | null;
  deal_code?: string | null;
  payment_structure?: string | null;
  synergies_description?: string | null;
  search_vector?: string | null;
  // -- backward-compat fields (legacy pages) --
  /** @deprecated Use deal_value */
  amount?: number;
  /** @deprecated Use client_id */
  company_id?: number | string;
  /** @deprecated Contacts are now linked via client_id */
  contact_ids?: (number | string)[];
  /** @deprecated Use deal_type */
  category?: string;
  /** @deprecated Use expected_close_date */
  expected_closing_date?: string;
  /** @deprecated Use lead_consultant or owner_id */
  sales_id?: number | string;
  /** @deprecated */
  index?: number;
  /** @deprecated */
  archived_at?: string;
}

// ── Task ────────────────────────────────────────────────────

export interface Task {
  id: string; // UUID
  title: string;
  description: string | null;
  status: string;
  priority: string | null;
  due_date: string | null;
  completion_date: string | null;
  assigned_to: string | null; // UUID
  created_by: string | null; // UUID
  client_id: string | null; // UUID
  deal_id: string | null; // UUID
  entity_id: string | null;
  organization_id: string | null;
  tags: string[] | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
  // -- backward-compat fields --
  /** @deprecated Use completion_date */
  done_date?: string | null;
  /** @deprecated Use title */
  text?: string;
  /** @deprecated Use metadata.type or tags */
  type?: string;
  /** @deprecated Use client_id */
  contact_id?: number | string;
  /** @deprecated Use assigned_to */
  sales_id?: number | string;
}

// ── Notes ───────────────────────────────────────────────────

export interface ConsultantNote {
  id: string; // UUID
  client_id: string | null;
  deal_id: string | null;
  text: string;
  date: string;
  created_by: string | null;
  status: string | null;
  attachments: AttachmentNote[] | null;
  created_at: string;
  updated_at: string;
  // -- backward-compat --
  /** @deprecated Use client_id */
  contact_id?: number | string;
  /** @deprecated Use created_by */
  sales_id?: number | string;
}

/** Backward-compat aliases */
export type ContactNote = ConsultantNote;
export type DealNote = ConsultantNote;

// ── Tags ────────────────────────────────────────────────────

export interface Tag {
  id: number;
  name: string;
  color: string;
}

// ── Helper / legacy types ───────────────────────────────────

export interface RAFile {
  src: string;
  title: string;
  path?: string;
  rawFile?: File;
  type?: string;
}

export type AttachmentNote = RAFile;

export interface EmailAndType {
  email: string;
  type: "Work" | "Home" | "Other";
}

export interface PhoneNumberAndType {
  number: string;
  type: "Work" | "Home" | "Other";
}

export interface DealStage {
  value: string;
  label: string;
}

export interface NoteStatus {
  value: string;
  label: string;
  color: string;
}

// ── Auth types ──────────────────────────────────────────────

export interface AuthUser {
  id: string;
  email: string;
  profile?: UserProfile;
  /** @deprecated Use profile */
  sale?: StaffUser;
}

// ── Dashboard stats ─────────────────────────────────────────

export interface DashboardStats {
  totalClients: number;
  totalDeals: number;
  totalDealValue: number;
  totalTasks: number;
  activeClients: number;
  recentActivity: Activity[];
  /** @deprecated Use totalClients */
  totalContacts?: number;
  /** @deprecated No separate companies table */
  totalCompanies?: number;
  /** @deprecated Use totalDealValue */
  totalRevenue?: number;
}

export interface Activity {
  id: number | string;
  type:
    | "client_created"
    | "deal_created"
    | "task_created"
    | "note_created"
    | "contact_created"
    | "company_created";
  date: string;
  description: string;
  user_id?: string;
  /** @deprecated Use user_id */
  sales_id?: number | string;
}
