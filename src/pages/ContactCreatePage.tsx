import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard } from "../components/ui/MobileCard";
import type { Company, EmailAndType, PhoneNumberAndType } from "../types";

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

type ContactType = "Work" | "Home" | "Other";

interface FormState {
  first_name: string;
  last_name: string;
  title: string;
  company_id: string;
  email: string;
  email_type: ContactType;
  phone: string;
  phone_type: ContactType;
  gender: string;
  status: string;
  background: string;
  has_newsletter: boolean;
}

const initialForm: FormState = {
  first_name: "",
  last_name: "",
  title: "",
  company_id: "",
  email: "",
  email_type: "Work",
  phone: "",
  phone_type: "Work",
  gender: "",
  status: "cold",
  background: "",
  has_newsletter: false,
};

export function ContactCreatePage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { sale } = useAuth();

  const [form, setForm] = useState<FormState>(initialForm);
  const [errors, setErrors] = useState<Partial<Record<keyof FormState, string>>>({});

  // Fetch companies for the dropdown
  const { data: companies = [] } = useQuery<Pick<Company, "id" | "name">[]>({
    queryKey: ["companies-select"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("companies")
        .select("id, name")
        .order("name");
      if (error) throw error;
      return data ?? [];
    },
  });

  // Insert mutation
  const mutation = useMutation({
    mutationFn: async (formData: FormState) => {
      if (!sale) throw new Error("Not authenticated");

      const email_jsonb: EmailAndType[] = formData.email.trim()
        ? [{ email: formData.email.trim(), type: formData.email_type }]
        : [];

      const phone_jsonb: PhoneNumberAndType[] = formData.phone.trim()
        ? [{ number: formData.phone.trim(), type: formData.phone_type }]
        : [];

      const now = new Date().toISOString();

      const insertPayload = {
        first_name: formData.first_name.trim(),
        last_name: formData.last_name.trim(),
        title: formData.title.trim() || null,
        company_id: formData.company_id ? Number(formData.company_id) : null,
        email_jsonb: email_jsonb.length > 0 ? email_jsonb : null,
        phone_jsonb: phone_jsonb.length > 0 ? phone_jsonb : null,
        gender: formData.gender || null,
        status: formData.status,
        background: formData.background.trim() || null,
        has_newsletter: formData.has_newsletter,
        sales_id: sale.id,
        first_seen: now,
        last_seen: now,
        tags: [],
      };

      const { data, error } = await supabase
        .from("contacts")
        .insert(insertPayload)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["contacts"] });
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

    if (!form.first_name.trim()) {
      newErrors.first_name = "First name is required";
    }
    if (!form.last_name.trim()) {
      newErrors.last_name = "Last name is required";
    }
    if (form.email.trim() && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim())) {
      newErrors.email = "Enter a valid email address";
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

        {/* Name section */}
        <MobileCard className="flex flex-col gap-4">
          <div className="flex flex-col gap-4 sm:flex-row sm:gap-3">
            <div className="flex-1">
              <label htmlFor="first_name" className={labelClassName} style={labelStyle}>
                First Name <span style={{ color: "var(--danger)" }}>*</span>
              </label>
              <input
                id="first_name"
                type="text"
                autoComplete="given-name"
                autoCapitalize="words"
                placeholder="First name"
                value={form.first_name}
                onChange={(e) => updateField("first_name", e.target.value)}
                className={inputClassName}
                style={{
                  ...inputStyle,
                  ...(errors.first_name
                    ? { borderColor: "var(--danger)" }
                    : {}),
                  minHeight: 48,
                }}
              />
              {errors.first_name && (
                <p className="text-xs mt-1" style={{ color: "var(--danger)" }}>
                  {errors.first_name}
                </p>
              )}
            </div>

            <div className="flex-1">
              <label htmlFor="last_name" className={labelClassName} style={labelStyle}>
                Last Name <span style={{ color: "var(--danger)" }}>*</span>
              </label>
              <input
                id="last_name"
                type="text"
                autoComplete="family-name"
                autoCapitalize="words"
                placeholder="Last name"
                value={form.last_name}
                onChange={(e) => updateField("last_name", e.target.value)}
                className={inputClassName}
                style={{
                  ...inputStyle,
                  ...(errors.last_name
                    ? { borderColor: "var(--danger)" }
                    : {}),
                  minHeight: 48,
                }}
              />
              {errors.last_name && (
                <p className="text-xs mt-1" style={{ color: "var(--danger)" }}>
                  {errors.last_name}
                </p>
              )}
            </div>
          </div>

          <div>
            <label htmlFor="contact_title" className={labelClassName} style={labelStyle}>
              Title
            </label>
            <input
              id="contact_title"
              type="text"
              autoCapitalize="words"
              placeholder="e.g. VP of Sales"
              value={form.title}
              onChange={(e) => updateField("title", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48 }}
            />
          </div>
        </MobileCard>

        {/* Company & Status */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="company_id" className={labelClassName} style={labelStyle}>
              Company
            </label>
            <select
              id="company_id"
              value={form.company_id}
              onChange={(e) => updateField("company_id", e.target.value)}
              className={inputClassName}
              style={{ ...inputStyle, minHeight: 48, appearance: "none" as const }}
            >
              <option value="">-- No company --</option>
              {companies.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          <div className="flex gap-3">
            <div className="flex-1">
              <label htmlFor="gender" className={labelClassName} style={labelStyle}>
                Gender
              </label>
              <select
                id="gender"
                value={form.gender}
                onChange={(e) => updateField("gender", e.target.value)}
                className={inputClassName}
                style={{ ...inputStyle, minHeight: 48, appearance: "none" as const }}
              >
                <option value="">-- Select --</option>
                <option value="Male">Male</option>
                <option value="Female">Female</option>
                <option value="Non-binary">Non-binary</option>
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
                <option value="cold">Cold</option>
                <option value="warm">Warm</option>
                <option value="hot">Hot</option>
              </select>
            </div>
          </div>
        </MobileCard>

        {/* Contact info */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="email" className={labelClassName} style={labelStyle}>
              Email
            </label>
            <div className="flex gap-2">
              <input
                id="email"
                type="email"
                inputMode="email"
                autoComplete="email"
                autoCapitalize="off"
                autoCorrect="off"
                spellCheck={false}
                placeholder="email@example.com"
                value={form.email}
                onChange={(e) => updateField("email", e.target.value)}
                className={inputClassName + " flex-1"}
                style={{
                  ...inputStyle,
                  ...(errors.email ? { borderColor: "var(--danger)" } : {}),
                  minHeight: 48,
                }}
              />
              <select
                aria-label="Email type"
                value={form.email_type}
                onChange={(e) => updateField("email_type", e.target.value as ContactType)}
                className="px-2 py-3 rounded-xl border text-xs outline-none focus:border-[var(--gold)] transition-colors shrink-0"
                style={{ ...inputStyle, minHeight: 48, width: 80, appearance: "none" as const }}
              >
                <option value="Work">Work</option>
                <option value="Home">Home</option>
                <option value="Other">Other</option>
              </select>
            </div>
            {errors.email && (
              <p className="text-xs mt-1" style={{ color: "var(--danger)" }}>
                {errors.email}
              </p>
            )}
          </div>

          <div>
            <label htmlFor="phone" className={labelClassName} style={labelStyle}>
              Phone
            </label>
            <div className="flex gap-2">
              <input
                id="phone"
                type="tel"
                inputMode="tel"
                autoComplete="tel"
                placeholder="+1 (555) 000-0000"
                value={form.phone}
                onChange={(e) => updateField("phone", e.target.value)}
                className={inputClassName + " flex-1"}
                style={{ ...inputStyle, minHeight: 48 }}
              />
              <select
                aria-label="Phone type"
                value={form.phone_type}
                onChange={(e) => updateField("phone_type", e.target.value as ContactType)}
                className="px-2 py-3 rounded-xl border text-xs outline-none focus:border-[var(--gold)] transition-colors shrink-0"
                style={{ ...inputStyle, minHeight: 48, width: 80, appearance: "none" as const }}
              >
                <option value="Work">Work</option>
                <option value="Home">Home</option>
                <option value="Other">Other</option>
              </select>
            </div>
          </div>
        </MobileCard>

        {/* Background & Newsletter */}
        <MobileCard className="flex flex-col gap-4">
          <div>
            <label htmlFor="background" className={labelClassName} style={labelStyle}>
              Background
            </label>
            <textarea
              id="background"
              rows={4}
              placeholder="Notes about this contact..."
              value={form.background}
              onChange={(e) => updateField("background", e.target.value)}
              className={inputClassName + " resize-none"}
              style={{ ...inputStyle, minHeight: 100 }}
            />
          </div>

          <label
            htmlFor="has_newsletter"
            className="flex items-center gap-3 cursor-pointer py-1"
          >
            <div className="relative">
              <input
                id="has_newsletter"
                type="checkbox"
                checked={form.has_newsletter}
                onChange={(e) => updateField("has_newsletter", e.target.checked)}
                className="sr-only peer"
              />
              <div
                className="w-11 h-6 rounded-full transition-colors peer-checked:bg-[var(--gold)]"
                style={{
                  background: form.has_newsletter
                    ? "var(--gold)"
                    : "var(--border-color)",
                }}
              />
              <div
                className="absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white transition-transform shadow-sm"
                style={{
                  transform: form.has_newsletter
                    ? "translateX(20px)"
                    : "translateX(0)",
                }}
              />
            </div>
            <span className="text-sm" style={{ color: "var(--text-primary)" }}>
              Subscribe to newsletter
            </span>
          </label>
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
