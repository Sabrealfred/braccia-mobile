import { Search, X } from "lucide-react";
import { useRef } from "react";

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export function SearchBar({
  value,
  onChange,
  placeholder = "Search...",
}: SearchBarProps) {
  const inputRef = useRef<HTMLInputElement>(null);

  return (
    <div className="px-4 py-2">
      <div
        className="flex items-center gap-2 px-3 py-2.5 rounded-xl"
        style={{ background: "var(--bg-input)" }}
      >
        <Search size={18} style={{ color: "var(--text-muted)" }} />
        <input
          ref={inputRef}
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className="flex-1 bg-transparent outline-none text-sm"
          style={{ color: "var(--text-primary)" }}
        />
        {value && (
          <button
            onClick={() => {
              onChange("");
              inputRef.current?.focus();
            }}
            className="p-0.5"
          >
            <X size={16} style={{ color: "var(--text-muted)" }} />
          </button>
        )}
      </div>
    </div>
  );
}
