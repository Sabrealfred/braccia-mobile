// ============================================================
// Braccia Mobile CRM — Shared Types
// Mirror of atomic-crm types for Supabase compatibility
// ============================================================

export interface Sale {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  administrator: boolean;
  disabled?: boolean;
  user_id: string;
  avatar?: RAFile;
}

export interface Company {
  id: number;
  name: string;
  logo?: RAFile;
  sector: string;
  size: 1 | 10 | 50 | 250 | 500;
  linkedin_url?: string;
  website?: string;
  phone_number?: string;
  address?: string;
  zipcode?: string;
  city?: string;
  stateAbbr?: string;
  sales_id: number;
  created_at: string;
  description?: string;
  revenue?: string;
  tax_identifier?: string;
  country?: string;
  context_links?: string[];
  nb_contacts?: number;
  nb_deals?: number;
}

export interface Contact {
  id: number;
  first_name: string;
  last_name: string;
  title?: string;
  company_id?: number;
  email_jsonb?: EmailAndType[];
  avatar?: Partial<RAFile>;
  linkedin_url?: string;
  first_seen: string;
  last_seen: string;
  has_newsletter: boolean;
  tags: number[];
  gender?: string;
  sales_id: number;
  status: string;
  background?: string;
  phone_jsonb?: PhoneNumberAndType[];
  nb_tasks?: number;
  company_name?: string;
}

export interface Deal {
  id: number;
  name: string;
  company_id: number;
  contact_ids: number[];
  category: string;
  stage: string;
  description?: string;
  amount: number;
  created_at: string;
  updated_at: string;
  archived_at?: string;
  expected_closing_date?: string;
  sales_id: number;
  index: number;
}

export interface ContactNote {
  id: number;
  contact_id: number;
  text: string;
  date: string;
  sales_id: number;
  status: string;
  attachments?: AttachmentNote[];
}

export interface DealNote {
  id: number;
  deal_id: number;
  text: string;
  date: string;
  sales_id: number;
  attachments?: AttachmentNote[];
}

export interface Tag {
  id: number;
  name: string;
  color: string;
}

export interface Task {
  id: number;
  contact_id: number;
  type: string;
  text: string;
  due_date: string;
  done_date?: string | null;
  sales_id?: number;
}

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

// Auth types
export interface AuthUser {
  id: string;
  email: string;
  sale?: Sale;
}

// Dashboard stats
export interface DashboardStats {
  totalContacts: number;
  totalCompanies: number;
  totalDeals: number;
  totalRevenue: number;
  recentActivity: Activity[];
}

export interface Activity {
  id: number;
  type: "contact_created" | "company_created" | "deal_created" | "note_created";
  date: string;
  description: string;
  sales_id?: number;
}
