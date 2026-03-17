import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider, useAuth } from "./providers/AuthProvider";
import { MobileShell } from "./components/layout/MobileShell";
import { LoginPage } from "./pages/LoginPage";
import { DashboardPage } from "./pages/DashboardPage";
import { ContactsPage } from "./pages/ContactsPage";
import { ContactDetailPage } from "./pages/ContactDetailPage";
import { ContactCreatePage } from "./pages/ContactCreatePage";
import { CompaniesPage } from "./pages/CompaniesPage";
import { CompanyDetailPage } from "./pages/CompanyDetailPage";
import { CompanyCreatePage } from "./pages/CompanyCreatePage";
import { DealsPage } from "./pages/DealsPage";
import { DealDetailPage } from "./pages/DealDetailPage";
import { DealCreatePage } from "./pages/DealCreatePage";
import { StaffPage } from "./pages/StaffPage";
import { StaffDetailPage } from "./pages/StaffDetailPage";
import { SettingsPage } from "./pages/SettingsPage";
import { TasksPage } from "./pages/TasksPage";
import { NotesPage } from "./pages/NotesPage";
import type { ReactNode } from "react";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 2,
      retry: 1,
    },
  },
});

function ProtectedRoute({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  if (loading) {
    return (
      <div
        className="flex items-center justify-center min-h-[100dvh]"
        style={{ background: "var(--bg-primary)" }}
      >
        <div
          className="w-10 h-10 rounded-full border-3 border-t-transparent animate-spin"
          style={{ borderColor: "var(--gold)", borderTopColor: "transparent" }}
        />
      </div>
    );
  }
  if (!user) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route
              element={
                <ProtectedRoute>
                  <MobileShell />
                </ProtectedRoute>
              }
            >
              <Route path="/" element={<DashboardPage />} />
              <Route path="/contacts" element={<ContactsPage />} />
              <Route path="/contacts/create" element={<ContactCreatePage />} />
              <Route path="/contacts/:id" element={<ContactDetailPage />} />
              <Route path="/companies" element={<CompaniesPage />} />
              <Route path="/companies/create" element={<CompanyCreatePage />} />
              <Route path="/companies/:id" element={<CompanyDetailPage />} />
              <Route path="/deals" element={<DealsPage />} />
              <Route path="/deals/create" element={<DealCreatePage />} />
              <Route path="/deals/:id" element={<DealDetailPage />} />
              <Route path="/staff" element={<StaffPage />} />
              <Route path="/staff/:id" element={<StaffDetailPage />} />
              <Route path="/settings" element={<SettingsPage />} />
              <Route path="/tasks" element={<TasksPage />} />
              <Route path="/notes" element={<NotesPage />} />
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}
