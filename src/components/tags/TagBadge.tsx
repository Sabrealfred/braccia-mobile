import { X } from "lucide-react";
import { cn } from "../../lib/utils";
import type { Tag } from "../../types";

interface TagBadgeProps {
  tag: Tag;
  size?: "sm" | "md";
  removable?: boolean;
  onRemove?: () => void;
  selected?: boolean;
  outline?: boolean;
  onClick?: () => void;
}

export function TagBadge({
  tag,
  size = "md",
  removable = false,
  onRemove,
  selected = false,
  outline = false,
  onClick,
}: TagBadgeProps) {
  const sizeClasses = size === "sm" ? "px-2 py-0.5 text-[10px]" : "px-3 py-1 text-xs";

  return (
    <span
      role={onClick ? "button" : undefined}
      tabIndex={onClick ? 0 : undefined}
      onClick={onClick}
      onKeyDown={onClick ? (e) => { if (e.key === "Enter" || e.key === " ") onClick(); } : undefined}
      className={cn(
        "inline-flex items-center gap-1 rounded-full font-medium whitespace-nowrap transition-colors",
        sizeClasses,
        onClick && "cursor-pointer",
      )}
      style={
        outline
          ? {
              border: `1.5px solid ${tag.color}`,
              color: tag.color,
              background: "transparent",
            }
          : selected
            ? {
                backgroundColor: tag.color,
                color: "#fff",
              }
            : {
                backgroundColor: `${tag.color}33`, // ~20% opacity
                color: tag.color,
              }
      }
    >
      {tag.name}
      {removable && (
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            onRemove?.();
          }}
          className="ml-0.5 rounded-full p-0.5 hover:opacity-70 transition-opacity"
          style={{ color: "inherit" }}
          aria-label={`Remove ${tag.name}`}
        >
          <X size={size === "sm" ? 10 : 12} />
        </button>
      )}
    </span>
  );
}
