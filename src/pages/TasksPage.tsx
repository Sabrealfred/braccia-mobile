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
import { formatDate } from "../lib/utils";
import { PageHeader } from "../components/ui/PageHeader";
import { MobileCard } from "../components/ui/MobileCard";
import { SectionTitle } from "../components/ui/MobileCard";
import { Badge } from "../components/ui/Badge";
import { EmptyState } from "../components/ui/EmptyState";
import { ListSkeleton } from "../components/ui/Skeleton";
import type { Task } from "../types";

// ----- Types -----

type FilterTab = "all" | "pending" | "in_progress" | "completed" | "overdue";

interface TaskWithClient extends Task {
  clients?: {
    name: string;
    full_name: string | null;
  } | null;
}

interface NewTaskForm {
  title: string;
  description: string;
  priority: string;
  due_date: string;
  client_id: string;
  deal_id: string;
}

const PRIORITIES = ["low", "medium", "high", "critical"] as const;

const priorityVariantMap: Record<string, "default" | "info" | "warning" | "danger"> = {
  low: "default",
  medium: "info",
  high: "warning",
  critical: "danger",
};

const priorityLabelMap: Record<string, string> = {
  low: "Low",
  medium: "Medium",
  high: "High",
  critical: "Critical",
};

// ----- Helpers -----

function isOverdue(task: TaskWithClient): boolean {
  if (task.status === "completed") return false;
  if (!task.due_date) return false;
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

function getDueDateColor(task: TaskWithClient): string {
  if (task.status === "completed") return "var(--text-muted)";
  if (!task.due_date) return "var(--text-muted)";
  if (isOverdue(task)) return "var(--danger)";
  if (isToday(task.due_date)) return "var(--gold)";
  return "var(--text-muted)";
}

function getDueDateLabel(task: TaskWithClient): string {
  if (!task.due_date) return "No due date";
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

async function fetchTasks(): Promise<TaskWithClient[]> {
  const { data, error } = await supabase
    .from("tasks")
    .select("*, clients(name, full_name)")
    .order("due_date");
  if (error) throw error;
  return data ?? [];
}

async function fetchClients(): Promise<{ id: string; name: string; full_name: string | null }[]> {
  const { data, error } = await supabase
    .from("clients")
    .select("id, name, full_name")
    .order("name");
  if (error) throw error;
  return data ?? [];
}

async function fetchDeals(): Promise<{ id: string; name: string }[]> {
  const { data, error } = await supabase
    .from("deals")
    .select("id, name")
    .eq("is_active", true)
    .order("name");
  if (error) throw error;
  return data ?? [];
}

// ----- Component -----

export function TasksPage() {
  const navigate = useNavigate();
  const { sale, user } = useAuth();
  const queryClient = useQueryClient();

  const [activeTab, setActiveTab] = useState<FilterTab>("all");
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState<NewTaskForm>({
    title: "",
    description: "",
    priority: "medium",
    due_date: new Date().toISOString().split("T")[0],
    client_id: "",
    deal_id: "",
  });

  // Fetch tasks
  const {
    data: tasks,
    isLoading,
    isError,
    error,
  } = useQuery<TaskWithClient[]>({
    queryKey: ["tasks"],
    queryFn: fetchTasks,
  });

  // Fetch clients for the form dropdown
  const { data: clientsList } = useQuery({
    queryKey: ["clients-list"],
    queryFn: fetchClients,
    enabled: showForm,
  });

  // Fetch deals for the form dropdown
  const { data: dealsList } = useQuery({
    queryKey: ["deals-list"],
    queryFn: fetchDeals,
    enabled: showForm,
  });

  // Toggle done mutation
  const toggleDone = useMutation({
    mutationFn: async (task: TaskWithClient) => {
      const isDone = task.status === "completed";
      const updates = isDone
        ? { status: "pending", completion_date: null }
        : { status: "completed", completion_date: new Date().toISOString() };
      const { error } = await supabase
        .from("tasks")
        .update(updates)
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
      const userId = user?.id ?? sale?.id;
      const { error } = await supabase.from("tasks").insert({
        title: data.title,
        description: data.description || null,
        priority: data.priority,
        status: "pending",
        due_date: data.due_date || null,
        client_id: data.client_id || null,
        deal_id: data.deal_id || null,
        assigned_to: userId,
        created_by: userId,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["tasks"] });
      setShowForm(false);
      setForm({
        title: "",
        description: "",
        priority: "medium",
        due_date: new Date().toISOString().split("T")[0],
        client_id: "",
        deal_id: "",
      });
    },
  });

  // Categorize tasks
  const categorized = useMemo(() => {
    if (!tasks) return { pending: [], in_progress: [], overdue: [], completed: [] };

    const pending: TaskWithClient[] = [];
    const in_progress: TaskWithClient[] = [];
    const overdue: TaskWithClient[] = [];
    const completed: TaskWithClient[] = [];

    for (const task of tasks) {
      if (task.status === "completed") {
        completed.push(task);
      } else if (isOverdue(task)) {
        overdue.push(task);
      } else if (task.status === "in_progress") {
        in_progress.push(task);
      } else {
        pending.push(task);
      }
    }

    return { pending, in_progress, overdue, completed };
  }, [tasks]);

  // Filter based on active tab
  const filteredTasks = useMemo(() => {
    switch (activeTab) {
      case "pending":
        return categorized.pending;
      case "in_progress":
        return categorized.in_progress;
      case "overdue":
        return categorized.overdue;
      case "completed":
        return categorized.completed;
      default:
        return [
          ...categorized.overdue,
          ...categorized.in_progress,
          ...categorized.pending,
          ...categorized.completed,
        ];
    }
  }, [activeTab, categorized]);

  const tabCounts = useMemo(
    () => ({
      all: tasks?.length ?? 0,
      pending: categorized.pending.length,
      in_progress: categorized.in_progress.length,
      overdue: categorized.overdue.length,
      completed: categorized.completed.length,
    }),
    [tasks, categorized]
  );

  const tabs: { key: FilterTab; label: string }[] = [
    { key: "all", label: "All" },
    { key: "pending", label: "Pending" },
    { key: "in_progress", label: "In Progress" },
    { key: "completed", label: "Completed" },
    { key: "overdue", label: "Overdue" },
  ];

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.title.trim()) return;
    createTask.mutate(form);
  }

  // ----- Render helpers -----

  function renderTaskRow(task: TaskWithClient) {
    const isDone = task.status === "completed";
    const overdue = isOverdue(task);
    const clientName = task.clients?.name || task.clients?.full_name || null;
    const priority = task.priority || "medium";

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
            <Badge variant={priorityVariantMap[priority] ?? "default"}>
              {priorityLabelMap[priority] ?? priority}
            </Badge>
            {task.status === "in_progress" && (
              <Badge variant="gold">In Progress</Badge>
            )}
            {overdue && !isDone && (
              <Badge variant="danger">Overdue</Badge>
            )}
          </div>

          <p
            className="text-sm font-medium mt-1"
            style={{
              color: "var(--text-primary)",
              textDecoration: isDone ? "line-through" : "none",
            }}
          >
            {task.title}
          </p>

          {task.description && (
            <p
              className="text-xs mt-0.5"
              style={{
                color: "var(--text-secondary)",
                display: "-webkit-box",
                WebkitLineClamp: 2,
                WebkitBoxOrient: "vertical",
                overflow: "hidden",
              }}
            >
              {task.description}
            </p>
          )}

          {/* Due date */}
          {task.due_date && (
            <div className="flex items-center gap-1 mt-1">
              <Clock size={12} style={{ color: getDueDateColor(task) }} />
              <span
                className="text-[11px] font-medium"
                style={{ color: getDueDateColor(task) }}
              >
                {getDueDateLabel(task)}
              </span>
            </div>
          )}

          {/* Client link */}
          {clientName && (
            <button
              onClick={() => navigate(`/clients/${task.client_id}`)}
              className="flex items-center gap-1 mt-1.5 active:opacity-70 transition-opacity"
            >
              <span
                className="text-xs font-medium"
                style={{ color: "var(--gold)" }}
              >
                {clientName}
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

            {/* Title input */}
            <input
              type="text"
              placeholder="Task title..."
              value={form.title}
              onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
              className="w-full rounded-lg px-3 py-2 text-sm"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            />

            {/* Description input */}
            <textarea
              placeholder="Description (optional)..."
              value={form.description}
              onChange={(e) =>
                setForm((f) => ({ ...f, description: e.target.value }))
              }
              rows={2}
              className="w-full rounded-lg px-3 py-2 text-sm resize-none"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            />

            {/* Priority select */}
            <select
              value={form.priority}
              onChange={(e) =>
                setForm((f) => ({ ...f, priority: e.target.value }))
              }
              className="w-full rounded-lg px-3 py-2 text-sm"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            >
              {PRIORITIES.map((p) => (
                <option key={p} value={p}>
                  {priorityLabelMap[p]}
                </option>
              ))}
            </select>

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

            {/* Client select */}
            <select
              value={form.client_id}
              onChange={(e) =>
                setForm((f) => ({ ...f, client_id: e.target.value }))
              }
              className="w-full rounded-lg px-3 py-2 text-sm"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            >
              <option value="">Select client (optional)...</option>
              {clientsList?.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.full_name || c.name}
                </option>
              ))}
            </select>

            {/* Deal select */}
            <select
              value={form.deal_id}
              onChange={(e) =>
                setForm((f) => ({ ...f, deal_id: e.target.value }))
              }
              className="w-full rounded-lg px-3 py-2 text-sm"
              style={{
                background: "var(--bg-primary)",
                color: "var(--text-primary)",
                border: "1px solid var(--border-light)",
              }}
            >
              <option value="">Select deal (optional)...</option>
              {dealsList?.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.name}
                </option>
              ))}
            </select>

            {/* Submit */}
            <button
              type="submit"
              disabled={!form.title.trim() || createTask.isPending}
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
              : `No ${activeTab.replace("_", " ")} tasks`
          }
          description={
            activeTab === "all"
              ? "Create your first task to stay organized."
              : `You don't have any ${activeTab.replace("_", " ")} tasks right now.`
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

      {/* Task list -- grouped when on "all" tab */}
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
              {categorized.in_progress.length > 0 && (
                <div>
                  <SectionTitle count={categorized.in_progress.length}>
                    In Progress
                  </SectionTitle>
                  {categorized.in_progress.map(renderTaskRow)}
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
