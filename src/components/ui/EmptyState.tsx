import type { ReactNode } from "react";
import type { LucideIcon } from "lucide-react";

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description?: string;
  action?: ReactNode;
}

export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
}: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-8 text-center">
      <Icon
        size={48}
        strokeWidth={1.2}
        style={{ color: "var(--text-muted)", opacity: 0.4 }}
      />
      <h3
        className="mt-4 text-base font-semibold"
        style={{ color: "var(--text-secondary)" }}
      >
        {title}
      </h3>
      {description && (
        <p
          className="mt-1.5 text-sm max-w-xs"
          style={{ color: "var(--text-muted)" }}
        >
          {description}
        </p>
      )}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}
