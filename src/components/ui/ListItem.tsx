import { type ReactNode, type HTMLAttributes } from "react";
import { cn } from "../../lib/utils";

interface ListItemProps {
  avatar: ReactNode;
  title: string;
  subtitle?: string;
  meta?: ReactNode;
  badge?: ReactNode;
  onClick?: () => void;
  trailing?: ReactNode;
  className?: string;
}

function ChevronRight() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 16 16"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
    >
      <path
        d="M6 3L11 8L6 13"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function ListItem({
  avatar,
  title,
  subtitle,
  meta,
  badge,
  onClick,
  trailing,
  className,
}: ListItemProps) {
  const isInteractive = !!onClick;

  const classes = cn(
    "flex items-center gap-3 w-full min-h-[48px] px-4 py-3 text-left",
    "border-b border-[var(--border-light)] last:border-b-0",
    "transition-colors duration-150",
    isInteractive && [
      "cursor-pointer",
      "active:bg-[var(--bg-muted)]/50",
      "hover:bg-[var(--bg-secondary)]",
    ],
    className
  );

  const inner = (
    <>
      {/* Avatar */}
      <div className="shrink-0">{avatar}</div>

      {/* Content: title + subtitle */}
      <div className="flex-1 min-w-0">
        <p
          className="text-sm font-semibold truncate"
          style={{ color: "var(--text-primary)" }}
        >
          {title}
        </p>
        {subtitle && (
          <p
            className="text-xs truncate mt-0.5"
            style={{ color: "var(--text-muted)" }}
          >
            {subtitle}
          </p>
        )}
      </div>

      {/* Badge + Meta */}
      {(badge || meta) && (
        <div className="shrink-0 flex flex-col items-end gap-1">
          {badge}
          {meta && (
            <span
              className="text-[11px] whitespace-nowrap"
              style={{ color: "var(--text-muted)" }}
            >
              {meta}
            </span>
          )}
        </div>
      )}

      {/* Trailing icon */}
      <div
        className="shrink-0 ml-1"
        style={{ color: "var(--text-muted)" }}
      >
        {trailing !== undefined ? trailing : isInteractive ? <ChevronRight /> : null}
      </div>
    </>
  );

  if (isInteractive) {
    return (
      <button type="button" onClick={onClick} className={classes}>
        {inner}
      </button>
    );
  }

  return <div className={classes}>{inner}</div>;
}

/* ── ListGroup: optional wrapper that adds card styling around ListItems ── */

interface ListGroupProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode;
}

export function ListGroup({ children, className, ...props }: ListGroupProps) {
  return (
    <div
      className={cn("card-mobile overflow-hidden", className)}
      role="list"
      {...props}
    >
      {children}
    </div>
  );
}
