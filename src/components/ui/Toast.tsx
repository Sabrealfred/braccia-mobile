import {
  createContext,
  useContext,
  useCallback,
  useState,
  useEffect,
  useRef,
  type ReactNode,
} from "react";
import { cn } from "../../lib/utils";

/* ── Types ───────────────────────────────────────────────────────────── */

type ToastType = "success" | "error" | "info" | "warning";

interface Toast {
  id: string;
  type: ToastType;
  message: string;
  duration?: number;
}

interface ToastContextValue {
  toast: (message: string, type?: ToastType, duration?: number) => void;
  success: (message: string, duration?: number) => void;
  error: (message: string, duration?: number) => void;
  info: (message: string, duration?: number) => void;
  warning: (message: string, duration?: number) => void;
}

/* ── Context ─────────────────────────────────────────────────────────── */

const ToastContext = createContext<ToastContextValue | null>(null);

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error("useToast must be used within a <ToastProvider>");
  }
  return ctx;
}

/* ── Icons ───────────────────────────────────────────────────────────── */

function SuccessIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
      <circle cx="9" cy="9" r="9" fill="var(--success)" fillOpacity="0.15" />
      <path
        d="M5.5 9.5L7.5 11.5L12.5 6.5"
        stroke="var(--success)"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function ErrorIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
      <circle cx="9" cy="9" r="9" fill="var(--danger)" fillOpacity="0.15" />
      <path
        d="M6.5 6.5L11.5 11.5M11.5 6.5L6.5 11.5"
        stroke="var(--danger)"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

function InfoIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
      <circle cx="9" cy="9" r="9" fill="var(--info)" fillOpacity="0.15" />
      <path
        d="M9 8V12.5M9 6V6.01"
        stroke="var(--info)"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

function WarningIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden="true">
      <circle cx="9" cy="9" r="9" fill="var(--gold)" fillOpacity="0.15" />
      <path
        d="M9 6V10M9 12V12.01"
        stroke="var(--gold)"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 14 14" fill="none" aria-hidden="true">
      <path
        d="M4 4L10 10M10 4L4 10"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

const iconMap: Record<ToastType, () => ReactNode> = {
  success: SuccessIcon,
  error: ErrorIcon,
  info: InfoIcon,
  warning: WarningIcon,
};

const borderColorMap: Record<ToastType, string> = {
  success: "var(--success)",
  error: "var(--danger)",
  info: "var(--info)",
  warning: "var(--gold)",
};

/* ── Toast Item ──────────────────────────────────────────────────────── */

const DEFAULT_DURATION = 3000;

interface ToastItemProps {
  toast: Toast;
  onDismiss: (id: string) => void;
}

function ToastItem({ toast: t, onDismiss }: ToastItemProps) {
  const [visible, setVisible] = useState(false);
  const [exiting, setExiting] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout>>(undefined);

  /* Mount: slide in */
  useEffect(() => {
    const frame = requestAnimationFrame(() => setVisible(true));
    return () => cancelAnimationFrame(frame);
  }, []);

  /* Auto-dismiss */
  useEffect(() => {
    const duration = t.duration ?? DEFAULT_DURATION;
    timerRef.current = setTimeout(() => dismiss(), duration);
    return () => clearTimeout(timerRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [t.id, t.duration]);

  const dismiss = useCallback(() => {
    setExiting(true);
    setTimeout(() => onDismiss(t.id), 200);
  }, [onDismiss, t.id]);

  const Icon = iconMap[t.type];

  return (
    <div
      role="alert"
      className={cn(
        "flex items-center gap-2.5 w-full max-w-[90vw] mx-auto px-4 py-3 rounded-xl shadow-lg",
        "transition-all duration-200 ease-out",
        visible && !exiting
          ? "translate-y-0 opacity-100"
          : "translate-y-4 opacity-0"
      )}
      style={{
        background: "var(--bg-card)",
        borderLeft: `3px solid ${borderColorMap[t.type]}`,
        boxShadow: "0 8px 24px rgba(0,0,0,0.12), 0 2px 8px rgba(0,0,0,0.08)",
      }}
    >
      <div className="shrink-0">
        <Icon />
      </div>

      <p
        className="flex-1 text-sm font-medium leading-snug"
        style={{ color: "var(--text-primary)" }}
      >
        {t.message}
      </p>

      <button
        type="button"
        onClick={dismiss}
        className={cn(
          "shrink-0 p-1 rounded-full transition-colors",
          "hover:bg-[var(--bg-muted)] active:bg-[var(--bg-muted)]"
        )}
        style={{ color: "var(--text-muted)" }}
        aria-label="Dismiss"
      >
        <CloseIcon />
      </button>
    </div>
  );
}

/* ── Provider ────────────────────────────────────────────────────────── */

let toastCounter = 0;

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const addToast = useCallback(
    (message: string, type: ToastType = "info", duration?: number) => {
      const id = `toast-${++toastCounter}-${Date.now()}`;
      setToasts((prev) => [...prev, { id, type, message, duration }]);
    },
    []
  );

  const contextValue: ToastContextValue = {
    toast: addToast,
    success: useCallback(
      (msg: string, dur?: number) => addToast(msg, "success", dur),
      [addToast]
    ),
    error: useCallback(
      (msg: string, dur?: number) => addToast(msg, "error", dur),
      [addToast]
    ),
    info: useCallback(
      (msg: string, dur?: number) => addToast(msg, "info", dur),
      [addToast]
    ),
    warning: useCallback(
      (msg: string, dur?: number) => addToast(msg, "warning", dur),
      [addToast]
    ),
  };

  return (
    <ToastContext.Provider value={contextValue}>
      {children}

      {/* Toast container — fixed at bottom, above safe area */}
      {toasts.length > 0 && (
        <div
          className="fixed bottom-0 left-0 right-0 z-[9999] flex flex-col gap-2 p-4 pointer-events-none"
          style={{
            paddingBottom:
              "calc(var(--safe-bottom, 0px) + var(--bottom-nav-height, 64px) + 16px)",
          }}
        >
          {toasts.map((t) => (
            <div key={t.id} className="pointer-events-auto">
              <ToastItem toast={t} onDismiss={removeToast} />
            </div>
          ))}
        </div>
      )}
    </ToastContext.Provider>
  );
}
