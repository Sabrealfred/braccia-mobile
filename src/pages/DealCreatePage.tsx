import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { X } from "lucide-react";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { PageHeader } from "../components/ui/PageHeader";
import type { Client } from "../types";

// ── Constants ────────────────────────────────────────────────

interface ClientOption {
  id: string;
  name: string;
}

const STAGES = [
  { value: "sourcing", label: "Sourcing" },
  { value: "nda", label: "NDA" },
  { value: "dd", label: "Due Diligence" },
  { value: "negotiation", label: "Negotiation" },
  { value: "legal", label: "Legal" },
  { value: "closed_won", label: "Closed Won" },
  { value: "closed_lost", label: "Closed Lost" },
];

const DEAL_TYPES = [
  "M&A",
  "Acquisition",
  "Divestiture",
  "Merger",
  "Investment",
  "Advisory",
  "Consulting",
  "Partnership",
  "Licensing",
  "Real Estate",
  "Other",
];

const PRIORITIES = [
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
  { value: "critical", label: "Critical" },
];

const CURRENCIES = ["USD", "EUR", "GBP", "CHF", "SGD", "CAD", "AUD"];

// ── Form shape ───────────────────────────────────────────────

interface DealForm {
  name: string;
  client_id: string;
  stage: string;
  deal_type: string;
  deal_value: string;
  currency: string;
  description: string;
  priority: string;
  expected_close_date: string;
  target_company: string;
  buyer_name: string;
  seller_name: string;
}

const initialForm: DealForm = {
  name: "",
  client_id: "",
  stage: "sourcing",
  deal_type: "",
  deal_value: "",
  currency: "USD",
  description: "",
  priority: "",
  expected_close_date: "",
  target_company: "",
  buyer_name: "",
  seller_name: "",
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
  const { user } = useAuth();

  const [form, setForm] = useState<DealForm>(initialForm);
  const [nameError, setNameError] = useState(false);
  const [clientSearch, setClientSearch] = useState("");
  const [clientDropdownOpen, setClientDropdownOpen] = useState(false);

  // ── Queries ──────────────────────────────────────────────

  const { data: clients = [] } = useQuery<ClientOption[]>({
    queryKey: ["clients-select"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("clients")
        .select("id, name")
        .order("name");
      if (error) throw error;
      return (data ?? []) as ClientOption[];
    },
  });

  const selectedClientId = form.client_id || null;

  // ── Derived ──────────────────────────────────────────────

  const filteredClients = useMemo(() => {
    if (!clientSearch.trim()) return clients;
    const term = clientSearch.toLowerCase();
    return clients.filter((c) => c.name.toLowerCase().includes(term));
  }, [clients, clientSearch]);

  const selectedClientName = useMemo(() => {
    if (!selectedClientId) return "";
    return clients.find((c) => c.id === selectedClientId)?.name ?? "";
  }, [clients, selectedClientId]);

  // ── Mutation ─────────────────────────────────────────────

  const mutation = useMutation({
    mutationFn: async (data: DealForm) => {
      const { error } = await supabase.from("deals").insert({
        name: data.name.trim(),
        client_id: data.client_id || null,
        stage: data.stage,
        deal_type: data.deal_type || null,
        deal_value: data.deal_value ? Number(data.deal_value) : null,
        currency: data.currency || "USD",
        description: data.description || null,
        priority: data.priority || null,
        expected_close_date: data.expected_close_date || null,
        target_company: data.target_company || null,
        buyer_name: data.buyer_name || null,
        seller_name: data.seller_name || null,
        created_by: user?.id ?? null,
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

  const handleSelectClient = (client: ClientOption) => {
    setForm((prev) => ({ ...prev, client_id: client.id }));
    setClientSearch("");
    setClientDropdownOpen(false);
  };

  const handleClearClient = () => {
    setForm((prev) => ({ ...prev, client_id: "" }));
    setClientSearch("");
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!form.name.trim()) {
      setNameError(true);
      return;
    }

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

        {/* Client (searchable) */}
        <div className="relative">
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Client
          </label>

          {selectedClientName ? (
            <div
              className={inputClass + " flex items-center justify-between"}
              style={inputStyle}
            >
              <span className="truncate">{selectedClientName}</span>
              <button
                type="button"
                onClick={handleClearClient}
                className="p-0.5 rounded-full ml-2 flex-shrink-0"
                style={{ color: "var(--text-muted)" }}
              >
                <X size={16} />
              </button>
            </div>
          ) : (
            <input
              type="text"
              value={clientSearch}
              onChange={(e) => {
                setClientSearch(e.target.value);
                setClientDropdownOpen(true);
              }}
              onFocus={() => setClientDropdownOpen(true)}
              placeholder="Search client..."
              className={inputClass}
              style={inputStyle}
            />
          )}

          {/* Client dropdown */}
          {clientDropdownOpen && !selectedClientName && (
            <div
              className="absolute left-0 right-0 z-20 mt-1 max-h-48 overflow-y-auto rounded-xl border shadow-lg"
              style={{
                background: "var(--bg-card)",
                borderColor: "var(--border-color)",
              }}
            >
              {filteredClients.length === 0 ? (
                <div
                  className="px-4 py-3 text-xs"
                  style={{ color: "var(--text-muted)" }}
                >
                  No clients found
                </div>
              ) : (
                filteredClients.map((client) => (
                  <button
                    key={client.id}
                    type="button"
                    onClick={() => handleSelectClient(client)}
                    className="w-full text-left px-4 py-2.5 text-sm transition-colors active:bg-[var(--bg-muted)]"
                    style={{
                      color: "var(--text-primary)",
                      borderBottom: "1px solid var(--border-light, var(--border-color))",
                    }}
                  >
                    {client.name}
                  </button>
                ))
              )}
            </div>
          )}
        </div>

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

        {/* Deal Type */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Deal Type
          </label>
          <select
            name="deal_type"
            value={form.deal_type}
            onChange={handleChange}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Select type</option>
            {DEAL_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>

        {/* Deal Value + Currency */}
        <div className="flex gap-3">
          <div className="flex-1">
            <label
              className={labelClass}
              style={{ color: "var(--text-secondary)" }}
            >
              Deal Value
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
                name="deal_value"
                value={form.deal_value}
                onChange={handleChange}
                placeholder="0"
                min="0"
                step="any"
                className={inputClass + " pl-8"}
                style={inputStyle}
              />
            </div>
          </div>
          <div className="w-28">
            <label
              className={labelClass}
              style={{ color: "var(--text-secondary)" }}
            >
              Currency
            </label>
            <select
              name="currency"
              value={form.currency}
              onChange={handleChange}
              className={inputClass}
              style={inputStyle}
            >
              {CURRENCIES.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Priority */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Priority
          </label>
          <select
            name="priority"
            value={form.priority}
            onChange={handleChange}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Select priority</option>
            {PRIORITIES.map((p) => (
              <option key={p.value} value={p.value}>
                {p.label}
              </option>
            ))}
          </select>
        </div>

        {/* Expected Close Date */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Expected Close Date
          </label>
          <input
            type="date"
            name="expected_close_date"
            value={form.expected_close_date}
            onChange={handleChange}
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Target Company */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Target Company
          </label>
          <input
            type="text"
            name="target_company"
            value={form.target_company}
            onChange={handleChange}
            placeholder="Target company name"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Buyer Name */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Buyer Name
          </label>
          <input
            type="text"
            name="buyer_name"
            value={form.buyer_name}
            onChange={handleChange}
            placeholder="Buyer name"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Seller Name */}
        <div>
          <label
            className={labelClass}
            style={{ color: "var(--text-secondary)" }}
          >
            Seller Name
          </label>
          <input
            type="text"
            name="seller_name"
            value={form.seller_name}
            onChange={handleChange}
            placeholder="Seller name"
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

      {/* Backdrop to close dropdown */}
      {clientDropdownOpen && (
        <div
          className="fixed inset-0 z-10"
          onClick={() => setClientDropdownOpen(false)}
        />
      )}
    </div>
  );
}
