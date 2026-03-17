import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard } from "../components/ui/MobileCard";

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

interface CompanyForm {
  name: string;
  industry: string;
  website: string;
  primary_phone: string;
  primary_email: string;
  address_line1: string;
  city: string;
  state: string;
  postal_code: string;
  country: string;
  annual_revenue: string;
  employee_count: string;
  tax_id: string;
  incorporation_country: string;
}

const initialForm: CompanyForm = {
  name: "",
  industry: "",
  website: "",
  primary_phone: "",
  primary_email: "",
  address_line1: "",
  city: "",
  state: "",
  postal_code: "",
  country: "",
  annual_revenue: "",
  employee_count: "",
  tax_id: "",
  incorporation_country: "",
};

export function CompanyCreatePage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { sale, user } = useAuth();
  const [form, setForm] = useState<CompanyForm>(initialForm);
  const [nameError, setNameError] = useState(false);

  const mutation = useMutation({
    mutationFn: async (data: CompanyForm) => {
      const userId = sale?.id ?? user?.id;
      if (!userId) throw new Error("Not authenticated");

      const { error } = await supabase.from("clients").insert({
        name: data.name.trim(),
        full_name: data.name.trim(),
        client_type: "entity",
        status: "active",
        industry: data.industry || null,
        website: data.website.trim() || null,
        primary_phone: data.primary_phone.trim() || null,
        primary_email: data.primary_email.trim() || null,
        address_line1: data.address_line1.trim() || null,
        city: data.city.trim() || null,
        state: data.state.trim() || null,
        postal_code: data.postal_code.trim() || null,
        country: data.country.trim() || null,
        annual_revenue: data.annual_revenue ? Number(data.annual_revenue) : null,
        employee_count: data.employee_count ? Number(data.employee_count) : null,
        tax_id: data.tax_id.trim() || null,
        incorporation_country: data.incorporation_country.trim() || null,
        tags: [],
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["companies"] });
      navigate("/companies");
    },
  });

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>,
  ) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    if (name === "name" && nameError) setNameError(false);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) {
      setNameError(true);
      return;
    }
    mutation.mutate(form);
  };

  return (
    <div
      className="min-h-[100dvh] pb-8"
      style={{ background: "var(--bg-primary)" }}
    >
      <PageHeader title="New Company" back />

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
                : "Failed to create company. Please try again."}
            </span>
          </div>
        )}

        {/* Name & Industry */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="name" className={labelClassName} style={labelStyle}>
              Company Name <span style={{ color: "var(--danger)" }}>*</span>
            </label>
            <input
              id="name"
              type="text"
              name="name"
              autoCapitalize="words"
              placeholder="Enter company name"
              value={form.name}
              onChange={handleChange}
              className={inputClassName}
              style={{
                ...inputStyle,
                ...(nameError ? { borderColor: "var(--danger)" } : {}),
                minHeight: 48,
              }}
            />
            {nameError && (
              <p className="text-xs mt-1" style={{ color: "var(--danger)" }}>
                Company name is required
              </p>
            )}
          </div>

          <div>
            <label htmlFor="industry" className={labelClassName} style={labelStyle}>
              Industry
            </label>
            <select
              id="industry"
              name="industry"
              value={form.industry}
              onChange={handleChange}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48, appearance: "none" as const }}
            >
              <option value="">-- Select --</option>
              {INDUSTRIES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>
        </MobileCard>

        {/* Contact info */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="website" className={labelClassName} style={labelStyle}>
              Website
            </label>
            <input
              id="website"
              type="url"
              name="website"
              value={form.website}
              onChange={handleChange}
              placeholder="https://example.com"
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>

          <div>
            <label htmlFor="primary_phone" className={labelClassName} style={labelStyle}>
              Phone
            </label>
            <input
              id="primary_phone"
              type="tel"
              name="primary_phone"
              inputMode="tel"
              value={form.primary_phone}
              onChange={handleChange}
              placeholder="+1 (555) 000-0000"
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>

          <div>
            <label htmlFor="primary_email" className={labelClassName} style={labelStyle}>
              Email
            </label>
            <input
              id="primary_email"
              type="email"
              name="primary_email"
              inputMode="email"
              autoCapitalize="off"
              value={form.primary_email}
              onChange={handleChange}
              placeholder="info@company.com"
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
              name="address_line1"
              value={form.address_line1}
              onChange={handleChange}
              placeholder="Street address"
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
                name="city"
                value={form.city}
                onChange={handleChange}
                placeholder="City"
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
                name="state"
                value={form.state}
                onChange={handleChange}
                placeholder="NY"
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
                name="postal_code"
                value={form.postal_code}
                onChange={handleChange}
                placeholder="10001"
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
                name="country"
                value={form.country}
                onChange={handleChange}
                placeholder="US"
                className={inputClassName}
                style={{ ...inputStyle, minHeight: 48 }}
              />
            </div>
          </div>
        </MobileCard>

        {/* Business details */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="annual_revenue" className={labelClassName} style={labelStyle}>
              Annual Revenue
            </label>
            <input
              id="annual_revenue"
              type="number"
              name="annual_revenue"
              inputMode="numeric"
              value={form.annual_revenue}
              onChange={handleChange}
              placeholder="e.g. 5000000"
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>

          <div>
            <label htmlFor="employee_count" className={labelClassName} style={labelStyle}>
              Employee Count
            </label>
            <input
              id="employee_count"
              type="number"
              name="employee_count"
              inputMode="numeric"
              value={form.employee_count}
              onChange={handleChange}
              placeholder="e.g. 50"
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>

          <div>
            <label htmlFor="tax_id" className={labelClassName} style={labelStyle}>
              Tax ID
            </label>
            <input
              id="tax_id"
              type="text"
              name="tax_id"
              value={form.tax_id}
              onChange={handleChange}
              placeholder="EIN / Tax ID"
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>

          <div>
            <label htmlFor="incorporation_country" className={labelClassName} style={labelStyle}>
              Incorporation Country
            </label>
            <input
              id="incorporation_country"
              type="text"
              name="incorporation_country"
              value={form.incorporation_country}
              onChange={handleChange}
              placeholder="e.g. US, UK, SG"
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
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
            "Create Company"
          )}
        </button>

        {/* Bottom spacing for safe area */}
        <div className="h-4" />
      </form>
    </div>
  );
}
