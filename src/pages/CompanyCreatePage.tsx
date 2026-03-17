import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { PageHeader } from "../components/ui/PageHeader";

const SECTORS = [
  "Technology",
  "Finance",
  "Healthcare",
  "Energy",
  "Real Estate",
  "Manufacturing",
  "Consulting",
  "Legal",
  "Other",
];

const SIZES = [1, 10, 50, 250, 500] as const;

interface CompanyForm {
  name: string;
  sector: string;
  size: string;
  website: string;
  phone_number: string;
  linkedin_url: string;
  address: string;
  city: string;
  stateAbbr: string;
  zipcode: string;
  country: string;
  revenue: string;
  tax_identifier: string;
  description: string;
}

const initialForm: CompanyForm = {
  name: "",
  sector: "",
  size: "",
  website: "",
  phone_number: "",
  linkedin_url: "",
  address: "",
  city: "",
  stateAbbr: "",
  zipcode: "",
  country: "",
  revenue: "",
  tax_identifier: "",
  description: "",
};

const inputStyle = {
  background: "var(--bg-input)",
  color: "var(--text-primary)",
  borderColor: "var(--border-color)",
};

const inputClass =
  "w-full px-4 py-3 rounded-xl border text-sm outline-none";

export function CompanyCreatePage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { sale } = useAuth();
  const [form, setForm] = useState<CompanyForm>(initialForm);
  const [nameError, setNameError] = useState(false);

  const mutation = useMutation({
    mutationFn: async (data: CompanyForm) => {
      const { error } = await supabase.from("companies").insert({
        name: data.name.trim(),
        sector: data.sector || null,
        size: data.size ? Number(data.size) : null,
        website: data.website || null,
        phone_number: data.phone_number || null,
        linkedin_url: data.linkedin_url || null,
        address: data.address || null,
        city: data.city || null,
        stateAbbr: data.stateAbbr || null,
        zipcode: data.zipcode || null,
        country: data.country || null,
        revenue: data.revenue || null,
        tax_identifier: data.tax_identifier || null,
        description: data.description || null,
        sales_id: sale!.id,
        created_at: new Date().toISOString(),
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["companies"] });
      navigate("/companies");
    },
  });

  const handleChange = (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement
    >
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
      className="min-h-screen"
      style={{ background: "var(--bg-primary)" }}
    >
      <PageHeader title="New Company" back />

      <form onSubmit={handleSubmit} className="px-4 pb-8 space-y-4">
        {/* Name (required) */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Company Name *
          </label>
          <input
            type="text"
            name="name"
            value={form.name}
            onChange={handleChange}
            placeholder="Enter company name"
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
              Company name is required
            </p>
          )}
        </div>

        {/* Sector */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Sector
          </label>
          <select
            name="sector"
            value={form.sector}
            onChange={handleChange}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Select sector</option>
            {SECTORS.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </div>

        {/* Size */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Size (employees)
          </label>
          <select
            name="size"
            value={form.size}
            onChange={handleChange}
            className={inputClass}
            style={inputStyle}
          >
            <option value="">Select size</option>
            {SIZES.map((s) => (
              <option key={s} value={s}>
                {s}+
              </option>
            ))}
          </select>
        </div>

        {/* Website */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Website
          </label>
          <input
            type="url"
            name="website"
            value={form.website}
            onChange={handleChange}
            placeholder="https://example.com"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Phone */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Phone
          </label>
          <input
            type="tel"
            name="phone_number"
            value={form.phone_number}
            onChange={handleChange}
            placeholder="+1 (555) 000-0000"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* LinkedIn */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            LinkedIn URL
          </label>
          <input
            type="url"
            name="linkedin_url"
            value={form.linkedin_url}
            onChange={handleChange}
            placeholder="https://linkedin.com/company/..."
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Address */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Address
          </label>
          <input
            type="text"
            name="address"
            value={form.address}
            onChange={handleChange}
            placeholder="Street address"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* City + State row */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label
              className="block text-xs font-medium mb-1.5"
              style={{ color: "var(--text-secondary)" }}
            >
              City
            </label>
            <input
              type="text"
              name="city"
              value={form.city}
              onChange={handleChange}
              placeholder="City"
              className={inputClass}
              style={inputStyle}
            />
          </div>
          <div>
            <label
              className="block text-xs font-medium mb-1.5"
              style={{ color: "var(--text-secondary)" }}
            >
              State
            </label>
            <input
              type="text"
              name="stateAbbr"
              value={form.stateAbbr}
              onChange={handleChange}
              placeholder="NY"
              className={inputClass}
              style={inputStyle}
            />
          </div>
        </div>

        {/* Zipcode + Country row */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label
              className="block text-xs font-medium mb-1.5"
              style={{ color: "var(--text-secondary)" }}
            >
              Zip Code
            </label>
            <input
              type="text"
              name="zipcode"
              value={form.zipcode}
              onChange={handleChange}
              placeholder="10001"
              className={inputClass}
              style={inputStyle}
            />
          </div>
          <div>
            <label
              className="block text-xs font-medium mb-1.5"
              style={{ color: "var(--text-secondary)" }}
            >
              Country
            </label>
            <input
              type="text"
              name="country"
              value={form.country}
              onChange={handleChange}
              placeholder="US"
              className={inputClass}
              style={inputStyle}
            />
          </div>
        </div>

        {/* Revenue */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Revenue
          </label>
          <input
            type="text"
            name="revenue"
            value={form.revenue}
            onChange={handleChange}
            placeholder="$1M"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Tax Identifier */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Tax Identifier
          </label>
          <input
            type="text"
            name="tax_identifier"
            value={form.tax_identifier}
            onChange={handleChange}
            placeholder="EIN / Tax ID"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        {/* Description */}
        <div>
          <label
            className="block text-xs font-medium mb-1.5"
            style={{ color: "var(--text-secondary)" }}
          >
            Description
          </label>
          <textarea
            name="description"
            value={form.description}
            onChange={handleChange}
            placeholder="Brief description of the company..."
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
            {(mutation.error as Error).message || "Failed to create company"}
          </p>
        )}

        {/* Submit */}
        <button
          type="submit"
          disabled={mutation.isPending}
          className="w-full py-3.5 rounded-xl font-semibold text-sm disabled:opacity-50"
          style={{ background: "var(--gold)", color: "white" }}
        >
          {mutation.isPending ? "Creating..." : "Create Company"}
        </button>
      </form>
    </div>
  );
}
