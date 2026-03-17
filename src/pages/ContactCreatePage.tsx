import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard } from "../components/ui/MobileCard";

const inputStyle = {
  background: "var(--bg-input)",
  color: "var(--text-primary)",
  borderColor: "var(--border-color)",
};

const inputClassName =
  "w-full px-4 py-3 rounded-xl border text-sm outline-none focus:border-[var(--gold)] transition-colors";

const labelClassName =
  "block text-xs font-medium uppercase tracking-wider mb-1.5";

const labelStyle = { color: "var(--text-muted)" };

const INDUSTRIES = [
  "Technology",
  "Finance",
  "Healthcare",
  "Energy",
  "Real Estate",
  "Manufacturing",
  "Legal",
  "Consulting",
  "Other",
];

const NET_WORTH_RANGES = [
  "$0-$1M",
  "$1M-$5M",
  "$5M-$10M",
  "$10M-$50M",
  "$50M+",
];

const RISK_PROFILES = [
  { value: "conservative", label: "Conservative" },
  { value: "moderate", label: "Moderate" },
  { value: "aggressive", label: "Aggressive" },
  { value: "very_aggressive", label: "Very Aggressive" },
];

interface FormState {
  name: string;
  primary_email: string;
  primary_phone: string;
  client_type: string;
  status: string;
  company: string;
  industry: string;
  website: string;
  address_line1: string;
  city: string;
  state: string;
  postal_code: string;
  country: string;
  net_worth_range: string;
  risk_profile: string;
  source: string;
  notes: string;
}

const initialForm: FormState = {
  name: "",
  primary_email: "",
  primary_phone: "",
  client_type: "individual",
  status: "prospect",
  company: "",
  industry: "",
  website: "",
  address_line1: "",
  city: "",
  state: "",
  postal_code: "",
  country: "",
  net_worth_range: "",
  risk_profile: "",
  source: "",
  notes: "",
};

export function ContactCreatePage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { sale, user } = useAuth();

  const [form, setForm] = useState<FormState>(initialForm);
  const [errors, setErrors] = useState<Partial<Record<keyof FormState, string>>>({});

  // Insert mutation
  const mutation = useMutation({
    mutationFn: async (formData: FormState) => {
      const userId = sale?.id ?? user?.id;
      if (!userId) throw new Error("Not authenticated");

      const insertPayload = {
        name: formData.name.trim(),
        full_name: formData.name.trim(),
        primary_email: formData.primary_email.trim() || null,
        primary_phone: formData.primary_phone.trim() || null,
        client_type: formData.client_type,
        status: formData.status,
        company: formData.company.trim() || null,
        industry: formData.industry || null,
        website: formData.website.trim() || null,
        address_line1: formData.address_line1.trim() || null,
        city: formData.city.trim() || null,
        state: formData.state.trim() || null,
        postal_code: formData.postal_code.trim() || null,
        country: formData.country.trim() || null,
        net_worth_range: formData.net_worth_range || null,
        risk_profile: formData.risk_profile || null,
        source: formData.source.trim() || null,
        notes: formData.notes.trim() || null,
        tags: [],
      };

      const { data, error } = await supabase
        .from("clients")
        .insert(insertPayload)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["clients"] });
      navigate("/contacts");
    },
  });

  function updateField<K extends keyof FormState>(key: K, value: FormState[K]) {
    setForm((prev) => ({ ...prev, [key]: value }));
    if (errors[key]) {
      setErrors((prev) => {
        const next = { ...prev };
        delete next[key];
        return next;
      });
    }
  }

  function validate(): boolean {
    const newErrors: Partial<Record<keyof FormState, string>> = {};

    if (!form.name.trim()) {
      newErrors.name = "Name is required";
    }
    if (
      form.primary_email.trim() &&
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.primary_email.trim())
    ) {
      newErrors.primary_email = "Enter a valid email address";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!validate()) return;
    mutation.mutate(form);
  }

  return (
    <div
      className="min-h-[100dvh] pb-8"
      style={{ background: "var(--bg-primary)" }}
    >
      <PageHeader title="New Contact" back="/contacts" />

      <form onSubmit={handleSubmit} className="px-4 flex flex-col gap-4" noValidate>
        {/* Error banner */}
        {mutation.isError && (
          <div
            className="flex items-start gap-2.5 rounded-xl px-3.5 py-3 text-sm"
            style={{
              background: "rgba(230, 57, 70, 0.12)",
              border: "1px solid rgba(230, 57, 70, 0.3)",
              color: "#f0a0a8",
            }}
          >
            <span className="shrink-0 mt-0.5">!</span>
            <span>
              {mutation.error instanceof Error
                ? mutation.error.message
                : "Failed to create contact. Please try again."}
            </span>
          </div>
        )}

        {/* Name & Type */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="name" className={labelClassName} style={labelStyle}>
              Name <span style={{ color: "var(--danger)" }}>*</span>
            </label>
            <input
              id="name"
              type="text"
              autoComplete="name"
              autoCapitalize="words"
              placeholder="Full name"
              value={form.name}
              onChange={(e) => updateField("name", e.target.value)}
              className={inputClassName}
              style={{
                ...inputStyle,
                ...(errors.name ? { borderColor: "var(--danger)" } : {}),
                minHeight: 48,
              }}
            />
            {errors.name && (
              <p className="text-xs mt-1" style={{ color: "var(--danger)" }}>
                {errors.name}
              </p>
            )}
          </div>

          <div className="flex gap-3">
            <div className="flex-1">
              <label htmlFor="client_type" className={labelClassName} style={labelStyle}>
                Type
              </label>
              <select
                id="client_type"
                value={form.client_type}
                onChange={(e) => updateField("client_type", e.target.value)}
                className={inputClassName}
                style={{ ...inputStyle, minHeight: 48, appearance: "none" as const }}
              >
                <option value="individual">Individual</option>
                <option value="entity">Entity</option>
              </select>
            </div>

            <div className="flex-1">
              <label htmlFor="status" className={labelClassName} style={labelStyle}>
                Status
              </label>
              <select
                id="status"
                value={form.status}
                onChange={(e) => updateField("status", e.target.value)}
                className={inputClassName}
                style={{ ...inputStyle, minHeight: 48, appearance: "none" as const }}
              >
                <option value="prospect">Prospect</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="archived">Archived</option>
              </select>
            </div>
          </div>
        </MobileCard>

        {/* Company & Industry */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="company" className={labelClassName} style={labelStyle}>
              Company
            </label>
            <input
              id="company"
              type="text"
              autoCapitalize="words"
              placeholder="Company name"
              value={form.company}
              onChange={(e) => updateField("company", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>

          <div>
            <label htmlFor="industry" className={labelClassName} style={labelStyle}>
              Industry
            </label>
            <select
              id="industry"
              value={form.industry}
              onChange={(e) => updateField("industry", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48, appearance: "none" as const }}
            >
              <option value="">-- Select --</option>
              {INDUSTRIES.map((ind) => (
                <option key={ind} value={ind}>
                  {ind}
                </option>
              ))}
            </select>
          </div>
        </MobileCard>

        {/* Contact info */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="primary_email" className={labelClassName} style={labelStyle}>
              Email
            </label>
            <input
              id="primary_email"
              type="email"
              inputMode="email"
              autoComplete="email"
              autoCapitalize="off"
              autoCorrect="off"
              spellCheck={false}
              placeholder="email@example.com"
              value={form.primary_email}
              onChange={(e) => updateField("primary_email", e.target.value)}
              className={inputClassName}
              style={{
                ...inputStyle,
                ...(errors.primary_email ? { borderColor: "var(--danger)" } : {}),
                minHeight: 48,
              }}
            />
            {errors.primary_email && (
              <p className="text-xs mt-1" style={{ color: "var(--danger)" }}>
                {errors.primary_email}
              </p>
            )}
          </div>

          <div>
            <label htmlFor="primary_phone" className={labelClassName} style={labelStyle}>
              Phone
            </label>
            <input
              id="primary_phone"
              type="tel"
              inputMode="tel"
              autoComplete="tel"
              placeholder="+1 (555) 000-0000"
              value={form.primary_phone}
              onChange={(e) => updateField("primary_phone", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>

          <div>
            <label htmlFor="website" className={labelClassName} style={labelStyle}>
              Website
            </label>
            <input
              id="website"
              type="url"
              placeholder="https://example.com"
              value={form.website}
              onChange={(e) => updateField("website", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>
        </MobileCard>

        {/* Address */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="address_line1" className={labelClassName} style={labelStyle}>
              Address
            </label>
            <input
              id="address_line1"
              type="text"
              autoComplete="street-address"
              placeholder="Street address"
              value={form.address_line1}
              onChange={(e) => updateField("address_line1", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>

          <div className="flex gap-3">
            <div className="flex-1">
              <label htmlFor="city" className={labelClassName} style={labelStyle}>
                City
              </label>
              <input
                id="city"
                type="text"
                autoComplete="address-level2"
                placeholder="City"
                value={form.city}
                onChange={(e) => updateField("city", e.target.value)}
                className={inputClassName}
                style={{ ...inputStyle, minHeight: 48 }}
              />
            </div>
            <div className="flex-1">
              <label htmlFor="state" className={labelClassName} style={labelStyle}>
                State
              </label>
              <input
                id="state"
                type="text"
                autoComplete="address-level1"
                placeholder="NY"
                value={form.state}
                onChange={(e) => updateField("state", e.target.value)}
                className={inputClassName}
                style={{ ...inputStyle, minHeight: 48 }}
              />
            </div>
          </div>

          <div className="flex gap-3">
            <div className="flex-1">
              <label htmlFor="postal_code" className={labelClassName} style={labelStyle}>
                Postal Code
              </label>
              <input
                id="postal_code"
                type="text"
                autoComplete="postal-code"
                placeholder="10001"
                value={form.postal_code}
                onChange={(e) => updateField("postal_code", e.target.value)}
                className={inputClassName}
                style={{ ...inputStyle, minHeight: 48 }}
              />
            </div>
            <div className="flex-1">
              <label htmlFor="country" className={labelClassName} style={labelStyle}>
                Country
              </label>
              <input
                id="country"
                type="text"
                autoComplete="country-name"
                placeholder="US"
                value={form.country}
                onChange={(e) => updateField("country", e.target.value)}
                className={inputClassName}
                style={{ ...inputStyle, minHeight: 48 }}
              />
            </div>
          </div>
        </MobileCard>

        {/* Financial Profile */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="net_worth_range" className={labelClassName} style={labelStyle}>
              Net Worth Range
            </label>
            <select
              id="net_worth_range"
              value={form.net_worth_range}
              onChange={(e) => updateField("net_worth_range", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48, appearance: "none" as const }}
            >
              <option value="">-- Select --</option>
              {NET_WORTH_RANGES.map((r) => (
                <option key={r} value={r}>
                  {r}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="risk_profile" className={labelClassName} style={labelStyle}>
              Risk Profile
            </label>
            <select
              id="risk_profile"
              value={form.risk_profile}
              onChange={(e) => updateField("risk_profile", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48, appearance: "none" as const }}
            >
              <option value="">-- Select --</option>
              {RISK_PROFILES.map((r) => (
                <option key={r.value} value={r.value}>
                  {r.label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="source" className={labelClassName} style={labelStyle}>
              Source
            </label>
            <input
              id="source"
              type="text"
              placeholder="e.g. Referral, LinkedIn, Event"
              value={form.source}
              onChange={(e) => updateField("source", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>
        </MobileCard>

        {/* Notes */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="notes" className={labelClassName} style={labelStyle}>
              Notes
            </label>
            <textarea
              id="notes"
              rows={4}
              placeholder="Notes about this client..."
              value={form.notes}
              onChange={(e) => updateField("notes", e.target.value)}
              className={inputClassName + " resize-none"}
              style={{ ...inputStyle, minHeight: 100 }}
            />
          </div>
        </MobileCard>

        {/* Submit */}
        <button
          type="submit"
          disabled={mutation.isPending}
          className="w-full rounded-xl text-sm font-semibold tracking-wide transition-all active:scale-[0.98]"
          style={{
            minHeight: 52,
            background: mutation.isPending ? "var(--gold-dim, var(--gold))" : "var(--gold)",
            color: "var(--white, #fff)",
            border: "none",
            opacity: mutation.isPending ? 0.8 : 1,
            cursor: mutation.isPending ? "not-allowed" : "pointer",
            boxShadow: "0 2px 12px rgba(184, 134, 11, 0.25)",
          }}
        >
          {mutation.isPending ? (
            <span className="flex items-center justify-center gap-2">
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                className="animate-spin"
              >
                <circle
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="rgba(255,255,255,0.3)"
                  strokeWidth="3"
                />
                <path
                  d="M12 2a10 10 0 0 1 10 10"
                  stroke="white"
                  strokeWidth="3"
                  strokeLinecap="round"
                />
              </svg>
              Creating...
            </span>
          ) : (
            "Create Contact"
          )}
        </button>

        {/* Bottom spacing for safe area */}
        <div className="h-4" />
      </form>
    </div>
  );
}
