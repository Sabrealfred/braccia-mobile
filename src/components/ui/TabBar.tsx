import {
  useRef,
  useEffect,
  useState,
  useCallback,
  type HTMLAttributes,
} from "react";
import { cn } from "../../lib/utils";

interface Tab {
  key: string;
  label: string;
  count?: number;
}

interface TabBarProps extends Omit<HTMLAttributes<HTMLDivElement>, "onChange"> {
  tabs: Tab[];
  activeTab: string;
  onChange: (key: string) => void;
}

interface IndicatorStyle {
  left: number;
  width: number;
}

export function TabBar({
  tabs,
  activeTab,
  onChange,
  className,
  ...props
}: TabBarProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const tabRefs = useRef<Map<string, HTMLButtonElement>>(new Map());
  const [indicator, setIndicator] = useState<IndicatorStyle>({ left: 0, width: 0 });
  const [ready, setReady] = useState(false);

  const updateIndicator = useCallback(() => {
    const container = containerRef.current;
    const activeEl = tabRefs.current.get(activeTab);
    if (!container || !activeEl) return;

    const containerRect = container.getBoundingClientRect();
    const activeRect = activeEl.getBoundingClientRect();

    setIndicator({
      left: activeRect.left - containerRect.left + container.scrollLeft,
      width: activeRect.width,
    });
    setReady(true);
  }, [activeTab]);

  /* Recalculate indicator on active tab change */
  useEffect(() => {
    updateIndicator();
  }, [updateIndicator]);

  /* Scroll active tab into view */
  useEffect(() => {
    const activeEl = tabRefs.current.get(activeTab);
    if (!activeEl) return;

    activeEl.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
      inline: "center",
    });
  }, [activeTab]);

  /* Recalculate on window resize */
  useEffect(() => {
    const onResize = () => updateIndicator();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, [updateIndicator]);

  const setTabRef = useCallback(
    (key: string) => (el: HTMLButtonElement | null) => {
      if (el) {
        tabRefs.current.set(key, el);
      } else {
        tabRefs.current.delete(key);
      }
    },
    []
  );

  return (
    <div
      ref={containerRef}
      className={cn(
        "relative flex overflow-x-auto scrollbar-hide",
        "border-b border-[var(--border-light)]",
        "-webkit-overflow-scrolling-touch",
        className
      )}
      role="tablist"
      style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
      {...props}
    >
      {tabs.map((tab) => {
        const isActive = tab.key === activeTab;

        return (
          <button
            key={tab.key}
            ref={setTabRef(tab.key)}
            role="tab"
            type="button"
            aria-selected={isActive}
            onClick={() => onChange(tab.key)}
            className={cn(
              "relative shrink-0 px-4 py-2.5 text-sm whitespace-nowrap",
              "transition-colors duration-200 outline-none",
              "focus-visible:ring-2 focus-visible:ring-[var(--gold)]/40 focus-visible:ring-offset-1 rounded-t",
              isActive
                ? "font-semibold text-[var(--text-primary)]"
                : "font-medium text-[var(--text-muted)] active:text-[var(--text-secondary)]"
            )}
          >
            <span className="flex items-center gap-1.5">
              {tab.label}
              {tab.count !== undefined && (
                <span
                  className={cn(
                    "inline-flex items-center justify-center min-w-[18px] h-[18px] px-1 rounded-full text-[10px] font-semibold",
                    isActive
                      ? "bg-[var(--gold)] text-white"
                      : "bg-[var(--bg-muted)] text-[var(--text-muted)]"
                  )}
                >
                  {tab.count}
                </span>
              )}
            </span>
          </button>
        );
      })}

      {/* Animated underline indicator */}
      <div
        className="absolute bottom-0 h-[2px] rounded-full"
        style={{
          background: "var(--gold)",
          left: indicator.left,
          width: indicator.width,
          transition: ready ? "left 250ms ease, width 250ms ease" : "none",
        }}
        aria-hidden="true"
      />
    </div>
  );
}
