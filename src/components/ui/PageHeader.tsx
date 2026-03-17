import { ArrowLeft } from "lucide-react";
import { useNavigate } from "react-router-dom";
import type { ReactNode } from "react";

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  back?: boolean | string;
  actions?: ReactNode;
}

export function PageHeader({ title, subtitle, back, actions }: PageHeaderProps) {
  const navigate = useNavigate();

  const handleBack = () => {
    if (typeof back === "string") {
      navigate(back);
    } else {
      navigate(-1);
    }
  };

  return (
    <div className="flex items-center gap-3 px-4 py-3">
      {back && (
        <button
          onClick={handleBack}
          className="p-1.5 -ml-1.5 rounded-full active:bg-[var(--bg-muted)] transition-colors"
        >
          <ArrowLeft size={22} style={{ color: "var(--text-primary)" }} />
        </button>
      )}
      <div className="flex-1 min-w-0">
        <h1 className="text-lg font-bold truncate" style={{ color: "var(--text-primary)" }}>
          {title}
        </h1>
        {subtitle && (
          <p className="text-xs truncate" style={{ color: "var(--text-muted)" }}>
            {subtitle}
          </p>
        )}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  );
}
