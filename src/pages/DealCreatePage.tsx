import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { X } from "lucide-react";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { PageHeader } from "../components/ui/PageHeader";
// ── Constants ────────────────────────────────────────────────

interface CompanyOption {
  id: number;
  name: string;
}

interface ContactOption {
  id: number;
  first_name: string;
  last_name: string;
}

const STAGES = [
  { value: "opportunity", label: "Opportunity" },
  { value: "proposal-sent", label: "Proposal Sent" },
  { value: "in-negotiation", label: "In Negotiation" },
  { value: "won", label: "Won" },
  { value: "lost", label: "Lost" },
  { value: "cancelled", label: "Cancelled" },
];

const CATEGORIES = [
  "M&A",
  "Investment",
  "Advisory",
  "Consulting",
  "Partnership",
  "Licensing",
  "Real Estate",
  "Other",
];

// ── Form shape ───────────────────────────────────────────────

interface DealForm {
  name: string;
  company_id: string;
  contact_ids: number[];
  stage: string;
  category: string;
  amount: string;
  expected_closing_date: string;
  description: string;
}

const initialForm: DealForm = {
  name: "",
  company_id: "",
  contact_ids: [],
  stage: "opportunity",
  category: "",
  amount: "",
  expected_closing_date: "",
  description: "",
};

// ── Style tokens ─────────────────────────────────────────────

const inputStyle = {
  background: "var(--bg-input)",
  color: "var(--text-primary)",
  borderColor: "var(--border-color)",
};

const inputClass =
  "w-full px-4 py-3 rounded-xl border text-sm outline-none";

const labelClass = "block text-xs font-medium mb-1.5";

// ── Component ────────────────────────────────────────────────

export function DealCreatePage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { sale } = useAuth();

  const [form, setForm] = useState<DealForm>(initialForm);
  const [nameError, setNameError] = useState(false);
  const [companyError, setCompanyError] = useState(false);
  const [companySearch, setCompanySearch] = useState("");
  const [companyDropdownOpen, setCompanyDropdownOpen] = useState(false);
  const [contactSearch, setContactSearch] = useState("");
  const [contactDropdownOpen, setContactDropdownOpen] = useState(false);

  // ── Queries ──────────────────────────────────────────────

  const { data: companies = [] } = useQuery<CompanyOption[]>({
    queryKey: ["companies-select"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("companies")
        .select("id, name")
        .order("name");
      if (error) throw error;
      return (data ?? []) as CompanyOption[];
    },
  });

  const selectedCompanyId = form.company_id ? Number(form.company_id) : null;

  const { data: contacts = [] } = useQuery<ContactOption[]>({
    queryKey: ["contacts-by-company", selectedCompanyId],
    queryFn: async () => {
      if (!selectedCompanyId) return [];
      const { data, error } = await supabase
        .from("contacts")
        .select("id, first_name, last_name")
        .eq("company_id", selectedCompanyId)
        .order("last_name");
      if (error) throw error;
      return (data ?? []) as ContactOption[];
    },
    enabled: !!selectedCompanyId,
  });

  // ── Derived ──────────────────────────────────────────────

  const filteredCompanies = useMemo(() => {
    if (!companySearch.trim()) return companies;
    const term = companySearch.toLowerCase();
    return companies.filter((c) => c.name.toLowerCase().includes(term));
  }, [companies, companySearch]);

  const filteredContacts = useMemo(() => {
    if (!contactSearch.trim()) return contacts;
    const term = contactSearch.toLowerCase();
    return contacts.filter(
      (c) =>
        c.first_name.toLowerCase().includes(term) ||
        c.last_name.toLowerCase().includes(term)
    );
  }, [contacts, contactSearch]);

  const selectedCompanyName = useMemo(() => {
    if (!selectedCompanyId) return "";
    return companies.find((c) => c.id === selectedCompanyId)?.name ?? "";
  }, [companies, selectedCompanyId]);

  const selectedContacts = useMemo(() => {
    return contacts.filter((c) => form.contact_ids.includes(c.id));
  }, [contacts, form.contact_ids]);

  // ── Mutation ─────────────────────────────────────────────

  const mutation = useMutation({
    mutationFn: async (data: DealForm) => {
      const now = new Date().toISOString();
      const { error } = await supabase.from("deals").insert({
        name: data.name.trim(),
        company_id: Number(data.company_id),
        contact_ids: data.contact_ids,
        stage: data.stage,
        category: data.category || null,
        amount: data.amount ? Number(data.amount) : 0,
        expected_closing_date: data.expected_closing_date || null,
        description: data.description || null,
        sales_id: sale!.id,
        created_at: now,
        updated_at: now,
        index: 0,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["deals"] });
      navigate("/deals");
    },
  });

  // ── Handlers ─────────────────────────────────────────────

  const handleChange = (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement
    >
  ) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    if (name === "name" && nameError) setNameError(false);
  };

  const handleSelectCompany = (company: CompanyOption) => {
    setForm((prev) => ({
      ...prev,
      company_id: String(company.id),
      contact_ids: [], // reset contacts when company changes
    }));
    setCompanySearch("");
    setCompanyDropdownOpen(false);
    if (companyError) setCompanyError(false);
  };

  const handleClearCompany = () => {
    setForm((prev) => ({ ...prev, company_id: "", contact_ids: [] }));
    setCompanySearch("");
  };

  const handleToggleContact = (contactId: number) => {
    setForm((prev) => {
      const ids = prev.contact_ids.includes(contactId)
        ? prev.contact_ids.filter((id) => id !== contactId)
        : [...prev.contact_ids, contactId];
      return { ...prev, contact_ids: ids };
    });
  };

  const handleRemoveContact = (contactId: number) => {
    setForm((prev) => ({
      ...prev,
      contact_ids: prev.contact_ids.filter((id) => id !== contactId),
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    let hasError = false;

    if (!form.name.trim()) {
      setNameError(true);
      hasError = true;
    }
    if (!form.company_id) {
      setCompanyError(true);
      hasError = true;
    }
    if (hasError) return;

    mutation.mutate(form);
  };

  // ── Render ───────────────────────────────────────────────

  return (
    <div
      className="min-h-screen"
      style={{ background: "var(--bg-primary)" }}
    >
      <PageHeader title="New Deal" back />

      <form onSubmit={handleSubmit} className="px-4 pb-8 space-y-4">
        {/* Deal Name (required) */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Deal Name *
          </label>
          <input
            type="text"
            name="name"
            value={form.name}
            onChange={handleChange}
            placeholder="Enter deal name"
            className={inputClass}
            style={{
              ...inputStyle,
              borderColor: nameError
                ? "var(--danger)"
                : "var(--border-color)",
            }}
          />
          {nameError && (
            <p
              className="text-xs mt-1"
              style={{ color: "var(--danger)" }}
            >
              Deal name is required
            </p>
          )}
        </div>

        {/* Company (required, searchable) */}
        <div className="relative">
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Company *
          </label>

          {selectedCompanyName ? (
            <div
              className={inputClass + " flex items-center justify-between"}
              style={{
                ...inputStyle,
                borderColor: companyError
                  ? "var(--danger)"
                  : "var(--border-color)",
              }}
            >
              <span className="truncate">{selectedCompanyName}</span>
              <button
                type="button"
                onClick={handleClearCompany}
                className="p-0.5 rounded-full ml-2 flex-shrink-0"
                style={{ color: "var(--text-muted)" }}
              >
                <X size={16} />
              </button>
            </div>
          ) : (
            <input
              type="text"
              value={companySearch}
              onChange={(e) => {
                setCompanySearch(e.target.value);
                setCompanyDropdownOpen(true);
              }}
              onFocus={() => setCompanyDropdownOpen(true)}
              placeholder="Search company..."
              className={inputClass}
              style={{
                ...inputStyle,
                borderColor: companyError
                  ? "var(--danger)"
                  : "var(--border-color)",
              }}
            />
          )}

          {companyError && !selectedCompanyName && (
            <p
              className="text-xs mt-1"
              style={{ color: "var(--danger)" }}
            >
              Company is required
            </p>
          )}

          {/* Company dropdown */}
          {companyDropdownOpen && !selectedCompanyName && (
            <div
              className="absolute left-0 right-0 z-20 mt-1 max-h-48 overflow-y-auto rounded-xl border shadow-lg"
              style={{
                background: "var(--bg-card)",
                borderColor: "var(--border-color)",
              }}
            >
              {filteredCompanies.length === 0 ? (
                <div
                  className="px-4 py-3 text-xs"
                  style={{ color: "var(--text-muted)" }}
                >
                  No companies found
                </div>
              ) : (
                filteredCompanies.map((company) => (
                  <button
                    key={company.id}
                    type="button"
                    onClick={() => handleSelectCompany(company)}
                    className="w-full text-left px-4 py-2.5 text-sm transition-colors active:bg-[var(--bg-muted)]"
                    style={{
                      color: "var(--text-primary)",
                      borderBottom: "1px solid var(--border-light, var(--border-color))",
                    }}
                  >
                    {company.name}
                  </button>
                ))
              )}
            </div>
          )}
        </div>

        {/* Contacts (multi-select, filtered by company) */}
        {selectedCompanyId && (
          <div className="relative">
            <label
              className={labelClass}
              style={{ color: "var(--text-secondary)" }}
            >
              Contacts
            </label>

            {/* Selected contact chips */}
            {selectedContacts.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mb-2">
                {selectedContacts.map((contact) => (
                  <span
                    key={contact.id}
                    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium"
                    style={{
                      background: "var(--bg-muted, rgba(255,255,255,0.08))",
                      color: "var(--gold)",
                    }}
                  >
                    {contact.first_name} {contact.last_name}
                    <button
                      type="button"
                      onClick={() => handleRemoveContact(contact.id)}
                      className="ml-0.5"
                      style={{ color: "var(--text-muted)" }}
                    >
                      <X size={12} />
                    </button>
                  </span>
                ))}
              </div>
            )}

            <input
              type="text"
              value={contactSearch}
              onChange={(e) => {
                setContactSearch(e.target.value);
                setContactDropdownOpen(true);
              }}
              onFocus={() => setContactDropdownOpen(true)}
              placeholder="Search contacts..."
              className={inputClass}
              style={inputStyle}
            />

            {/* Contacts dropdown */}
            {contactDropdownOpen && (
              <div
                className="absolute left-0 right-0 z-20 mt-1 max-h-48 overflow-y-auto rounded-xl border shadow-lg"
                style={{
                  background: "var(--bg-card)",
                  borderColor: "var(--border-color)",
                }}
              >
                {filteredContacts.length === 0 ? (
                  <div
                    className="px-4 py-3 text-xs"
                    style={{ color: "var(--text-muted)" }}
                  >
                    {contacts.length === 0
                      ? "No contacts for this company"
                      : "No matches found"}
                  </div>
                ) : (
                  filteredContacts.map((contact) => {
                    const isSelected = form.contact_ids.includes(contact.id);
                    return (
                      <button
                        key={contact.id}
                        type="button"
                        onClick={() => {
                          handleToggleContact(contact.id);
                          setContactSearch("");
                        }}
                        className="w-full text-left px-4 py-2.5 text-sm flex items-center justify-between transition-colors active:bg-[var(--bg-muted)]"
                        style={{
                          color: isSelected
                            ? "var(--gold)"
                            : "var(--text-primary)",
                          borderBottom:
                            "1px solid var(--border-light, var(--border-color))",
                        }}
                      >
                        <span>
                          {contact.first_name} {contact.last_name}
                        </span>
                        {isSelected && (
                          <span
                            className="text-xs font-medium"
                            style={{ color: "var(--gold)" }}
                          >
                            Selected
                          </span>
                        )}
                      </button>
                    );
                  })
                )}
              </div>
            )}
          </div>
        )}

        {/* Stage */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Stage
          </label>
          <select
            name="stage"
            value={form.stage}
            onChange={handleChange}
            className={inputClass}
            style={inputStyle}
          >
            {STAGES.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </div>

        {/* Category */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Category
          </label>
          <select
            name="category"
            value={form.category}
            onChange={handleChange}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Select category</option>
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </div>

        {/* Amount */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Amount
          </label>
          <div className="relative">
            <span
              className="absolute left-4 top-1/2 -translate-y-1/2 text-sm font-medium"
              style={{ color: "var(--text-muted)" }}
            >
              $
            </span>
            <input
              type="number"
              name="amount"
              value={form.amount}
              onChange={handleChange}
              placeholder="0"
              min="0"
              step="any"
              className={inputClass + " pl-8"}
              style={inputStyle}
            />
          </div>
        </div>

        {/* Expected Closing Date */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Expected Closing Date
          </label>
          <input
            type="date"
            name="expected_closing_date"
            value={form.expected_closing_date}
            onChange={handleChange}
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Description */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Description
          </label>
          <textarea
            name="description"
            value={form.description}
            onChange={handleChange}
            placeholder="Brief description of the deal..."
            rows={4}
            className={inputClass + " resize-none"}
            style={inputStyle}
          />
        </div>

        {/* Error message */}
        {mutation.isError && (
          <p
            className="text-xs text-center"
            style={{ color: "var(--danger)" }}
          >
            {(mutation.error as Error).message || "Failed to create deal"}
          </p>
        )}

        {/* Submit */}
        <button
          type="submit"
          disabled={mutation.isPending}
          className="w-full py-3.5 rounded-xl font-semibold text-sm disabled:opacity-50"
          style={{ background: "var(--gold)", color: "white" }}
        >
          {mutation.isPending ? "Creating..." : "Create Deal"}
        </button>
      </form>

      {/* Backdrop to close dropdowns */}
      {(companyDropdownOpen || contactDropdownOpen) && (
        <div
          className="fixed inset-0 z-10"
          onClick={() => {
            setCompanyDropdownOpen(false);
            setContactDropdownOpen(false);
          }}
        />
      )}
    </div>
  );
}
