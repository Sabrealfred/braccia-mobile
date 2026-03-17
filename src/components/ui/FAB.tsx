import { Plus } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { cn } from "../../lib/utils";

interface FABProps {
  to: string;
  icon?: React.ReactNode;
  label?: string;
  className?: string;
}

export function FAB({ to, icon, label, className }: FABProps) {
  const navigate = useNavigate();

  return (
    <button
      onClick={() => navigate(to)}
      aria-label={label ?? "Create new"}
      className={cn(
        "fixed z-50 flex items-center justify-center rounded-full fab-shadow active:scale-95 transition-transform",
        label ? "px-5 py-3.5 gap-2 bottom-24 right-4" : "w-14 h-14 bottom-24 right-4",
        className
      )}
      style={{ background: "var(--gold)", color: "var(--white)" }}
    >
      {icon ?? <Plus size={24} strokeWidth={2.5} />}
      {label && <span className="text-sm font-semibold">{label}</span>}
    </button>
  );
}
