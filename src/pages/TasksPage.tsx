import { useState, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  CheckCircle2,
  Circle,
  Clock,
  AlertCircle,
  ListTodo,
  Plus,
  X,
  ChevronRight,
} from "lucide-react";
import { supabase } from "../lib/supabase";
import { useAuth } from "../providers/AuthProvider";
import { formatDate, formatRelativeDate } from "../lib/utils";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard } from "../components/ui/MobileCard";
import { SectionTitle } from "../components/ui/MobileCard";
import { Badge } from "../components/ui/Badge";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import type { Task } from "../types";

// ----- Types -----

type FilterTab = "all" | "pending" | "completed" | "overdue";

interface TaskWithContact extends Task {
  contacts?: {
    first_name: string;
    last_name: string;
  } | null;
}

interface NewTaskForm {
  type: string;
  text: string;
  due_date: string;
  contact_id: string;
}

const TASK_TYPES = ["Email", "Phone", "Demo", "Meeting", "Follow-up"] as const;

const typeVariantMap: Record<string, "gold" | "info" | "success" | "warning" | "danger" | "default"> = {
  Email: "info",
  Phone: "gold",
  Demo: "success",
  Meeting: "warning",
  "Follow-up": "danger",
};

// ----- Helpers -----

function isOverdue(task: TaskWithContact): boolean {
  if (task.done_date) return false;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return new Date(task.due_date) < today;
}

function isToday(dateStr: string): boolean {
  const today = new Date();
  const d = new Date(dateStr);
  return (
    d.getFullYear() === today.getFullYear() &&
    d.getMonth() === today.getMonth() &&
    d.getDate() === today.getDate()
  );
}

function getDueDateColor(task: TaskWithContact): string {
  if (task.done_date) return "var(--text-muted)";
  if (isOverdue(task)) return "var(--danger)";
  if (isToday(task.due_date)) return "var(--gold)";
  return "var(--text-muted)";
}

function getDueDateLabel(task: TaskWithContact): string {
  if (isToday(task.due_date)) return "Today";
  const d = new Date(task.due_date);
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  d.setHours(0, 0, 0, 0);
  const diff = Math.round((d.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  if (diff === 1) return "Tomorrow";
  if (diff === -1) return "Yesterday";
  if (diff < 0) return `${Math.abs(diff)}d overdue`;
  if (diff <= 7) return `In ${diff}d`;
  return formatDate(task.due_date);
}

// ----- Data fetching -----

async function fetchTasks(): Promise<TaskWithContact[]> {
  const { data, error } = await supabase
    .from("tasks")
    .select("*, contacts(first_name, last_name)")
    .order("due_date");
  if (error) throw error;
  return data ?? [];
}

async function fetchContacts(): Promise<{ id: number; first_name: string; last_name: string }[]> {
  const { data, error } = await supabase
    .from("contacts")
    .select("id, first_name, last_name")
    .order("last_name");
  if (error) throw error;
  return data ?? [];
}

// ----- Component -----

export function TasksPage() {
  const navigate = useNavigate();
  const { sale } = useAuth();
  const queryClient = useQueryClient();

  const [activeTab, setActiveTab] = useState<FilterTab>("all");
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<NewTaskForm>({
    type: "Email",
    text: "",
    due_date: new Date().toISOString().split("T")[0],
    contact_id: "",
  });

  // Fetch tasks
  const {
    data: tasks,
    isLoading,
    isError,
    error,
  } = useQuery<TaskWithContact[]>({
    queryKey: ["tasks"],
    queryFn: fetchTasks,
  });

  // Fetch contacts for the form dropdown
  const { data: contactsList } = useQuery({
    queryKey: ["contacts-list"],
    queryFn: fetchContacts,
    enabled: showForm,
  });

  // Toggle done mutation
  const toggleDone = useMutation({
    mutationFn: async (task: TaskWithContact) => {
      const newDoneDate = task.done_date ? null : new Date().toISOString();
      const { error } = await supabase
        .from("tasks")
        .update({ done_date: newDoneDate })
        .eq("id", task.id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
    },
  });

  // Create task mutation
  const createTask = useMutation({
    mutationFn: async (data: NewTaskForm) => {
      const { error } = await supabase.from("tasks").insert({
        type: data.type,
        text: data.text,
        due_date: data.due_date,
        contact_id: parseInt(data.contact_id, 10),
        sales_id: sale?.id,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
      setShowForm(false);
      setForm({ type: "Email", text: "", due_date: new Date().toISOString().split("T")[0], contact_id: "" });
    },
  });

  // Categorize tasks
  const categorized = useMemo(() => {
    if (!tasks) return { pending: [], overdue: [], completed: [] };

    const pending: TaskWithContact[] = [];
    const overdue: TaskWithContact[] = [];
    const completed: TaskWithContact[] = [];

    for (const task of tasks) {
      if (task.done_date) {
        completed.push(task);
      } else if (isOverdue(task)) {
        overdue.push(task);
      } else {
        pending.push(task);
      }
    }

    return { pending, overdue, completed };
  }, [tasks]);

  // Filter based on active tab
  const filteredTasks = useMemo(() => {
    switch (activeTab) {
      case "pending":
        return categorized.pending;
      case "overdue":
        return categorized.overdue;
      case "completed":
        return categorized.completed;
      default:
        return [...categorized.overdue, ...categorized.pending, ...categorized.completed];
    }
  }, [activeTab, categorized]);

  const tabCounts = useMemo(
    () => ({
      all: tasks?.length ?? 0,
      pending: categorized.pending.length,
      overdue: categorized.overdue.length,
      completed: categorized.completed.length,
    }),
    [tasks, categorized]
  );

  const tabs: { key: FilterTab; label: string }[] = [
    { key: "all", label: "All" },
    { key: "pending", label: "Pending" },
    { key: "completed", label: "Completed" },
    { key: "overdue", label: "Overdue" },
  ];

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.text.trim() || !form.contact_id) return;
    createTask.mutate(form);
  }

  // ----- Render helpers -----

  function renderTaskRow(task: TaskWithContact) {
    const isDone = !!task.done_date;
    const overdue = isOverdue(task);

    return (
      <div
        key={task.id}
        className="flex items-start gap-3 px-4 py-3 transition-colors"
        style={{
          borderBottom: "1px solid var(--border-light)",
          opacity: isDone ? 0.55 : 1,
        }}
      >
        {/* Checkbox */}
        <button
          onClick={() => toggleDone.mutate(task)}
          className="mt-0.5 flex-shrink-0 transition-transform active:scale-90"
          disabled={toggleDone.isPending}
        >
          {isDone ? (
            <CheckCircle2 size={22} style={{ color: "var(--success)" }} />
          ) : overdue ? (
            <AlertCircle size={22} style={{ color: "var(--danger)" }} />
          ) : (
            <Circle size={22} style={{ color: "var(--text-muted)" }} />
          )}
        </button>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <Badge variant={typeVariantMap[task.type] ?? "default"}>
              {task.type}
            </Badge>
            {overdue && !isDone && (
              <Badge variant="danger">Overdue</Badge>
            )}
          </div>

          <p
            className="text-sm mt-1"
            style={{
              color: "var(--text-primary)",
              textDecoration: isDone ? "line-through" : "none",
            }}
          >
            {task.text}
          </p>

          {/* Due date */}
          <div className="flex items-center gap-1 mt-1">
            <Clock size={12} style={{ color: getDueDateColor(task) }} />
            <span
              className="text-[11px] font-medium"
              style={{ color: getDueDateColor(task) }}
            >
              {getDueDateLabel(task)}
            </span>
          </div>

          {/* Contact link */}
          {task.contacts && (
            <button
              onClick={() => navigate(`/contacts/${task.contact_id}`)}
              className="flex items-center gap-1 mt-1.5 active:opacity-70 transition-opacity"
            >
              <span
                className="text-xs font-medium"
                style={{ color: "var(--gold)" }}
              >
                {task.contacts.first_name} {task.contacts.last_name}
              </span>
              <ChevronRight size={12} style={{ color: "var(--gold)" }} />
            </button>
          )}
        </div>
      </div>
    );
  }

  // ----- Main render -----

  return (
    <div
      className="flex flex-col min-h-full pb-24"
      style={{ background: "var(--bg-primary)" }}
    >
      {/* Header */}
      <PageHeader
        title="Tasks"
        actions={
          <button
            onClick={() => setShowForm((v) => !v)}
            className="p-2 rounded-full active:bg-[var(--bg-muted)] transition-colors"
          >
            {showForm ? (
              <X size={20} style={{ color: "var(--text-primary)" }} />
            ) : (
              <Plus size={20} style={{ color: "var(--gold)" }} />
            )}
          </button>
        }
      />

      {/* Filter tabs */}
      <div
        className="flex gap-1 px-4 pb-3 overflow-x-auto"
        style={{ WebkitOverflowScrolling: "touch" }}
      >
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold whitespace-nowrap transition-colors active:scale-95"
            style={{
              background:
                activeTab === tab.key ? "var(--gold)" : "var(--bg-card)",
              color:
                activeTab === tab.key ? "#fff" : "var(--text-secondary)",
              border:
                activeTab === tab.key
                  ? "none"
                  : "1px solid var(--border-light)",
            }}
          >
            {tab.label}
            <span
              className="text-[10px] px-1.5 py-0.5 rounded-full font-bold"
              style={{
                background:
                  activeTab === tab.key
                    ? "rgba(255,255,255,0.25)"
                    : "var(--bg-muted)",
                color:
                  activeTab === tab.key ? "#fff" : "var(--text-muted)",
              }}
            >
              {tabCounts[tab.key]}
            </span>
          </button>
        ))}
      </div>

      {/* Add Task Form */}
      {showForm && (
        <MobileCard className="mx-4 mb-3">
          <form onSubmit={handleSubmit} className="space-y-3">
            <p
              className="text-sm font-semibold"
              style={{ color: "var(--text-primary)" }}
            >
              New Task
            </p>

            {/* Type select */}
            <select
              value={form.type}
              onChange={(e) => setForm((f) => ({ ...f, type: e.target.value }))}
              className="w-full rounded-lg px-3 py-2 text-sm"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            >
              {TASK_TYPES.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>

            {/* Text input */}
            <input
              type="text"
              placeholder="Task description..."
              value={form.text}
              onChange={(e) => setForm((f) => ({ ...f, text: e.target.value }))}
              className="w-full rounded-lg px-3 py-2 text-sm"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            />

            {/* Due date */}
            <input
              type="date"
              value={form.due_date}
              onChange={(e) =>
                setForm((f) => ({ ...f, due_date: e.target.value }))
              }
              className="w-full rounded-lg px-3 py-2 text-sm"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            />

            {/* Contact select */}
            <select
              value={form.contact_id}
              onChange={(e) =>
                setForm((f) => ({ ...f, contact_id: e.target.value }))
              }
              className="w-full rounded-lg px-3 py-2 text-sm"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            >
              <option value="">Select contact...</option>
              {contactsList?.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.first_name} {c.last_name}
                </option>
              ))}
            </select>

            {/* Submit */}
            <button
              type="submit"
              disabled={!form.text.trim() || !form.contact_id || createTask.isPending}
              className="w-full rounded-xl py-2.5 text-sm font-semibold transition-transform active:scale-[0.98] disabled:opacity-40"
              style={{ background: "var(--gold)", color: "#fff" }}
            >
              {createTask.isPending ? "Adding..." : "Add Task"}
            </button>

            {createTask.isError && (
              <p className="text-xs text-center" style={{ color: "var(--danger)" }}>
                {createTask.error instanceof Error
                  ? createTask.error.message
                  : "Failed to create task."}
              </p>
            )}
          </form>
        </MobileCard>
      )}

      {/* Loading */}
      {isLoading && <ListSkeleton count={6} />}

      {/* Error */}
      {isError && (
        <EmptyState
          icon={ListTodo}
          title="Failed to load tasks"
          description={
            error instanceof Error
              ? error.message
              : "An unexpected error occurred. Pull down to retry."
          }
        />
      )}

      {/* Empty state */}
      {!isLoading && !isError && filteredTasks.length === 0 && (
        <EmptyState
          icon={ListTodo}
          title={
            activeTab === "all"
              ? "No tasks yet"
              : `No ${activeTab} tasks`
          }
          description={
            activeTab === "all"
              ? "Create your first task to stay organized."
              : `You don't have any ${activeTab} tasks right now.`
          }
          action={
            activeTab === "all" && !showForm ? (
              <button
                onClick={() => setShowForm(true)}
                className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-transform active:scale-95"
                style={{ background: "var(--gold)", color: "#fff" }}
              >
                <Plus size={16} />
                Add Task
              </button>
            ) : undefined
          }
        />
      )}

      {/* Task list — grouped when on "all" tab */}
      {!isLoading && !isError && filteredTasks.length > 0 && (
        <div className="flex flex-col">
          {activeTab === "all" ? (
            <>
              {categorized.overdue.length > 0 && (
                <div>
                  <SectionTitle count={categorized.overdue.length}>
                    Overdue
                  </SectionTitle>
                  {categorized.overdue.map(renderTaskRow)}
                </div>
              )}
              {categorized.pending.length > 0 && (
                <div>
                  <SectionTitle count={categorized.pending.length}>
                    Pending
                  </SectionTitle>
                  {categorized.pending.map(renderTaskRow)}
                </div>
              )}
              {categorized.completed.length > 0 && (
                <div>
                  <SectionTitle count={categorized.completed.length}>
                    Completed
                  </SectionTitle>
                  {categorized.completed.map(renderTaskRow)}
                </div>
              )}
            </>
          ) : (
            <div>{filteredTasks.map(renderTaskRow)}</div>
          )}
        </div>
      )}
    </div>
  );
}
