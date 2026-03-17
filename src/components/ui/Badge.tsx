import { cn } from "../../lib/utils";
import type { ReactNode } from "react";

type BadgeVariant = "default" | "gold" | "success" | "warning" | "danger" | "info" | "outline";

const variantStyles: Record<BadgeVariant, string> = {
  default: "bg-[var(--bg-muted)] text-[var(--text-secondary)]",
  gold: "bg-[var(--gold)] text-white",
  success: "bg-[var(--success)] text-white",
  warning: "bg-[var(--warning)] text-[var(--charcoal)]",
  danger: "bg-[var(--danger)] text-white",
  info: "bg-[var(--info)] text-white",
  outline: "border border-[var(--border-color)] text-[var(--text-secondary)]",
};

interface BadgeProps {
  children: ReactNode;
  variant?: BadgeVariant;
  className?: string;
}

export function Badge({ children, variant = "default", className }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase tracking-wide",
        variantStyles[variant],
        className
      )}
    >
      {children}
    </span>
  );
}
