import { type ButtonHTMLAttributes, type ReactNode } from "react";
import { cn } from "../../lib/utils";

/* ============================================================
   Button — Braccia Capital Mobile CRM
   Variants: primary / secondary / outline / danger / ghost
   Sizes: sm / md / lg
   ============================================================ */

type ButtonVariant = "primary" | "secondary" | "outline" | "danger" | "ghost";
type ButtonSize = "sm" | "md" | "lg";

interface ButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "style"> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  fullWidth?: boolean;
  children: ReactNode;
}

/* Tailwind classes per variant */
const variantClasses: Record<ButtonVariant, string> = {
  primary: "text-white font-semibold",
  secondary: "font-medium",
  outline: "border font-medium bg-transparent",
  danger: "text-white font-semibold",
  ghost: "font-medium bg-transparent",
};

/* Inline styles per variant (CSS variables cannot be used in Tailwind arbitrary values reliably) */
function getVariantStyle(variant: ButtonVariant): React.CSSProperties {
  switch (variant) {
    case "primary":
      return {
        background: "var(--gold)",
        color: "#ffffff",
        boxShadow: "0 2px 12px rgba(184, 134, 11, 0.25)",
      };
    case "secondary":
      return {
        background: "var(--bg-muted)",
        color: "var(--text-primary)",
      };
    case "outline":
      return {
        background: "transparent",
        color: "var(--text-primary)",
        borderColor: "var(--border-color)",
      };
    case "danger":
      return {
        background: "var(--danger)",
        color: "#ffffff",
      };
    case "ghost":
      return {
        background: "transparent",
        color: "var(--text-muted)",
      };
  }
}

/* Size classes */
const sizeClasses: Record<ButtonSize, string> = {
  sm: "py-2 px-4 text-xs rounded-lg min-h-[36px]",
  md: "py-3 px-5 text-sm rounded-xl min-h-[44px]",
  lg: "py-3.5 px-6 text-sm rounded-xl min-h-[52px]",
};

/* Spinner SVG */
function Spinner({ size }: { size: ButtonSize }) {
  const px = size === "sm" ? 14 : 18;
  return (
    <svg
      width={px}
      height={px}
      viewBox="0 0 24 24"
      fill="none"
      className="animate-spin"
    >
      <circle
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="3"
        opacity="0.25"
      />
      <path
        d="M12 2a10 10 0 0 1 10 10"
        stroke="currentColor"
        strokeWidth="3"
        strokeLinecap="round"
      />
    </svg>
  );
}

export function Button({
  variant = "primary",
  size = "md",
  loading = false,
  fullWidth = false,
  disabled,
  children,
  type = "button",
  className,
  onClick,
  ...rest
}: ButtonProps) {
  const isDisabled = disabled || loading;

  return (
    <button
      type={type}
      disabled={isDisabled}
      onClick={onClick}
      className={cn(
        "inline-flex items-center justify-center gap-2 tracking-wide transition-all active:scale-[0.97]",
        variantClasses[variant],
        sizeClasses[size],
        fullWidth && "w-full",
        isDisabled && "opacity-60 cursor-not-allowed active:scale-100",
        className,
      )}
      style={getVariantStyle(variant)}
      {...rest}
    >
      {loading && <Spinner size={size} />}
      {children}
    </button>
  );
}
