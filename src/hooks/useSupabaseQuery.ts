import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "../lib/supabase";

// Generic list hook
export function useList<T>(
  table: string,
  options?: {
    select?: string;
    order?: { column: string; ascending?: boolean };
    filter?: Record<string, unknown>;
    search?: { columns: string[]; value: string };
    enabled?: boolean;
  }
) {
  return useQuery<T[]>({
    queryKey: [table, "list", options?.filter, options?.search],
    queryFn: async () => {
      let query = supabase
        .from(table)
        .select(options?.select ?? "*");

      if (options?.order) {
        query = query.order(options.order.column, {
          ascending: options.order.ascending ?? true,
        });
      }

      if (options?.filter) {
        Object.entries(options.filter).forEach(([key, value]) => {
          if (value !== undefined && value !== null && value !== "") {
            query = query.eq(key, value);
          }
        });
      }

      if (options?.search?.value && options.search.columns.length > 0) {
        const orClause = options.search.columns
          .map((col) => `${col}.ilike.%${options.search!.value}%`)
          .join(",");
        query = query.or(orClause);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as T[];
    },
    enabled: options?.enabled ?? true,
  });
}

// Generic get-one hook
export function useOne<T>(table: string, id: number | string | undefined) {
  return useQuery<T>({
    queryKey: [table, "one", id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from(table)
        .select("*")
        .eq("id", id!)
        .single();
      if (error) throw error;
      return data as T;
    },
    enabled: id !== undefined && id !== null,
  });
}

// Generic create hook
export function useCreate<T>(table: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (record: Partial<T>) => {
      const { data, error } = await supabase
        .from(table)
        .insert(record as Record<string, unknown>)
        .select()
        .single();
      if (error) throw error;
      return data as T;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [table] });
    },
  });
}

// Generic update hook
export function useUpdate<T>(table: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      ...record
    }: Partial<T> & { id: number | string }) => {
      const { data, error } = await supabase
        .from(table)
        .update(record as Record<string, unknown>)
        .eq("id", id)
        .select()
        .single();
      if (error) throw error;
      return data as T;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [table] });
    },
  });
}

// Generic delete hook
export function useDelete(table: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (id: number | string) => {
      const { error } = await supabase.from(table).delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [table] });
    },
  });
}
