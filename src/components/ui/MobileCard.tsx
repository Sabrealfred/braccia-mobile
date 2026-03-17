import { type ReactNode, type HTMLAttributes } from "react";
import { cn } from "../../lib/utils";

interface MobileCardProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode;
  noPadding?: boolean;
}

export function MobileCard({
  children,
  className,
  noPadding,
  ...props
}: MobileCardProps) {
  return (
    <div
      className={cn("card-mobile", !noPadding && "p-4", className)}
      {...props}
    >
      {children}
    </div>
  );
}

export function MobileCardHeader({
  children,
  className,
  ...props
}: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn("px-4 py-2.5 border-b", className)}
      style={{ borderColor: "var(--border-light)" }}
      {...props}
    >
      {children}
    </div>
  );
}

export function SectionTitle({
  children,
  count,
}: {
  children: ReactNode;
  count?: number;
}) {
  return (
    <div className="flex items-center gap-2 px-4 py-3">
      <span
        className="text-xs font-semibold uppercase tracking-wider"
        style={{ color: "var(--text-muted)" }}
      >
        {children}
      </span>
      {count !== undefined && (
        <span
          className="text-[10px] font-medium px-1.5 py-0.5 rounded-full"
          style={{
            background: "var(--bg-muted)",
            color: "var(--text-secondary)",
          }}
        >
          {count}
        </span>
      )}
    </div>
  );
}
