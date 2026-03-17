import { type InputHTMLAttributes, type SelectHTMLAttributes, type TextareaHTMLAttributes, useId } from "react";
import { cn } from "../../lib/utils";

/* ============================================================
   Shared styles — aligned with Braccia Capital theme
   ============================================================ */

const baseInputStyle = {
  background: "var(--bg-input)",
  color: "var(--text-primary)",
  borderColor: "var(--border-color)",
};

const baseInputClassName =
  "w-full px-4 py-3 rounded-xl border text-sm outline-none transition-colors focus:border-[var(--gold)]";

const labelClassName =
  "block text-sm font-medium mb-1.5";

const labelStyle = { color: "var(--text-secondary)" };

function ErrorMessage({ message }: { message?: string }) {
  if (!message) return null;
  return (
    <p className="text-xs mt-1" style={{ color: "var(--danger)" }}>
      {message}
    </p>
  );
}

function RequiredDot() {
  return <span style={{ color: "var(--danger)" }}> *</span>;
}

/* ============================================================
   TextInput
   ============================================================ */

interface TextInputProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, "onChange" | "value" | "type"> {
  label: string;
  name: string;
  type?: "text" | "email" | "tel" | "password" | "url" | "search";
  value: string;
  onChange: (value: string) => void;
  error?: string;
  className?: string;
}

export function TextInput({
  label,
  name,
  type = "text",
  value,
  onChange,
  placeholder,
  required,
  error,
  disabled,
  autoComplete,
  className,
  ...rest
}: TextInputProps) {
  const id = useId();

  return (
    <div className={cn("w-full", className)}>
      <label htmlFor={id} className={labelClassName} style={labelStyle}>
        {label}
        {required && <RequiredDot />}
      </label>
      <input
        id={id}
        name={name}
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        required={required}
        disabled={disabled}
        autoComplete={autoComplete}
        className={cn(
          baseInputClassName,
          disabled && "opacity-50 cursor-not-allowed",
        )}
        style={{
          ...baseInputStyle,
          minHeight: 48,
          ...(error ? { borderColor: "var(--danger)" } : {}),
        }}
        {...rest}
      />
      <ErrorMessage message={error} />
    </div>
  );
}

/* ============================================================
   SelectInput
   ============================================================ */

interface SelectOption {
  value: string;
  label: string;
}

interface SelectInputProps
  extends Omit<SelectHTMLAttributes<HTMLSelectElement>, "onChange" | "value"> {
  label: string;
  name: string;
  value: string;
  onChange: (value: string) => void;
  options: SelectOption[];
  placeholder?: string;
  required?: boolean;
  error?: string;
  className?: string;
}

export function SelectInput({
  label,
  name,
  value,
  onChange,
  options,
  placeholder,
  required,
  error,
  disabled,
  className,
  ...rest
}: SelectInputProps) {
  const id = useId();

  return (
    <div className={cn("w-full", className)}>
      <label htmlFor={id} className={labelClassName} style={labelStyle}>
        {label}
        {required && <RequiredDot />}
      </label>
      <div className="relative">
        <select
          id={id}
          name={name}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          required={required}
          disabled={disabled}
          className={cn(
            baseInputClassName,
            "pr-10",
            disabled && "opacity-50 cursor-not-allowed",
          )}
          style={{
            ...baseInputStyle,
            minHeight: 48,
            appearance: "none",
            ...(error ? { borderColor: "var(--danger)" } : {}),
          }}
          {...rest}
        >
          {placeholder && <option value="">{placeholder}</option>}
          {options.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
        {/* Chevron icon */}
        <div
          className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2"
          style={{ color: "var(--text-muted)" }}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="6 9 12 15 18 9" />
          </svg>
        </div>
      </div>
      <ErrorMessage message={error} />
    </div>
  );
}

/* ============================================================
   TextArea
   ============================================================ */

interface TextAreaProps
  extends Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, "onChange" | "value"> {
  label: string;
  name: string;
  value: string;
  onChange: (value: string) => void;
  rows?: number;
  required?: boolean;
  error?: string;
  className?: string;
}

export function TextArea({
  label,
  name,
  value,
  onChange,
  placeholder,
  rows = 4,
  required,
  error,
  disabled,
  className,
  ...rest
}: TextAreaProps) {
  const id = useId();

  return (
    <div className={cn("w-full", className)}>
      <label htmlFor={id} className={labelClassName} style={labelStyle}>
        {label}
        {required && <RequiredDot />}
      </label>
      <textarea
        id={id}
        name={name}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        rows={rows}
        required={required}
        disabled={disabled}
        className={cn(
          baseInputClassName,
          "resize-none",
          disabled && "opacity-50 cursor-not-allowed",
        )}
        style={{
          ...baseInputStyle,
          minHeight: rows * 24 + 24,
          ...(error ? { borderColor: "var(--danger)" } : {}),
        }}
        {...rest}
      />
      <ErrorMessage message={error} />
    </div>
  );
}

/* ============================================================
   ToggleInput — iOS-style switch (48x28px)
   ============================================================ */

interface ToggleInputProps {
  label: string;
  name: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
  description?: string;
  disabled?: boolean;
  className?: string;
}

export function ToggleInput({
  label,
  name,
  checked,
  onChange,
  description,
  disabled,
  className,
}: ToggleInputProps) {
  const id = useId();

  return (
    <label
      htmlFor={id}
      className={cn(
        "flex items-center justify-between gap-3 w-full min-h-[48px]",
        disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer",
        className,
      )}
    >
      <div className="flex-1 min-w-0">
        <span className="text-sm font-medium block" style={{ color: "var(--text-primary)" }}>
          {label}
        </span>
        {description && (
          <span className="text-xs block mt-0.5" style={{ color: "var(--text-muted)" }}>
            {description}
          </span>
        )}
      </div>
      <div className="relative shrink-0" style={{ width: 48, height: 28 }}>
        <input
          id={id}
          name={name}
          type="checkbox"
          checked={checked}
          onChange={(e) => !disabled && onChange(e.target.checked)}
          disabled={disabled}
          className="sr-only"
        />
        {/* Track */}
        <div
          className="absolute inset-0 rounded-full transition-colors duration-200"
          style={{
            background: checked ? "var(--gold)" : "var(--border-color)",
          }}
        />
        {/* Thumb */}
        <div
          className="absolute top-[3px] left-[3px] w-[22px] h-[22px] rounded-full bg-white shadow-sm transition-transform duration-200"
          style={{
            transform: checked ? "translateX(20px)" : "translateX(0)",
          }}
        />
      </div>
    </label>
  );
}

/* ============================================================
   DateInput
   ============================================================ */

interface DateInputProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, "onChange" | "value" | "type"> {
  label: string;
  name: string;
  value: string;
  onChange: (value: string) => void;
  required?: boolean;
  error?: string;
  className?: string;
}

export function DateInput({
  label,
  name,
  value,
  onChange,
  required,
  error,
  disabled,
  className,
  ...rest
}: DateInputProps) {
  const id = useId();

  return (
    <div className={cn("w-full", className)}>
      <label htmlFor={id} className={labelClassName} style={labelStyle}>
        {label}
        {required && <RequiredDot />}
      </label>
      <input
        id={id}
        name={name}
        type="date"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        required={required}
        disabled={disabled}
        className={cn(
          baseInputClassName,
          disabled && "opacity-50 cursor-not-allowed",
        )}
        style={{
          ...baseInputStyle,
          minHeight: 48,
          colorScheme: "auto",
          ...(error ? { borderColor: "var(--danger)" } : {}),
        }}
        {...rest}
      />
      <ErrorMessage message={error} />
    </div>
  );
}

/* ============================================================
   NumberInput — with optional prefix ($)
   ============================================================ */

interface NumberInputProps
  extends Omit<InputHTMLAttributes<HTMLInputElement>, "onChange" | "value" | "type" | "prefix"> {
  label: string;
  name: string;
  value: string;
  onChange: (value: string) => void;
  prefix?: string;
  required?: boolean;
  error?: string;
  className?: string;
}

export function NumberInput({
  label,
  name,
  value,
  onChange,
  prefix = "$",
  placeholder,
  required,
  error,
  disabled,
  className,
  ...rest
}: NumberInputProps) {
  const id = useId();

  return (
    <div className={cn("w-full", className)}>
      <label htmlFor={id} className={labelClassName} style={labelStyle}>
        {label}
        {required && <RequiredDot />}
      </label>
      <div className="relative">
        {prefix && (
          <div
            className="absolute left-4 top-1/2 -translate-y-1/2 text-sm font-medium pointer-events-none select-none"
            style={{ color: "var(--text-muted)" }}
          >
            {prefix}
          </div>
        )}
        <input
          id={id}
          name={name}
          type="text"
          inputMode="decimal"
          value={value}
          onChange={(e) => {
            const raw = e.target.value;
            // Allow digits, decimals, commas, and empty
            if (/^[\d.,]*$/.test(raw) || raw === "") {
              onChange(raw);
            }
          }}
          placeholder={placeholder}
          required={required}
          disabled={disabled}
          className={cn(
            baseInputClassName,
            prefix && "pl-9",
            disabled && "opacity-50 cursor-not-allowed",
          )}
          style={{
            ...baseInputStyle,
            minHeight: 48,
            ...(error ? { borderColor: "var(--danger)" } : {}),
          }}
          {...rest}
        />
      </div>
      <ErrorMessage message={error} />
    </div>
  );
}
