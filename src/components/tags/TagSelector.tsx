import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus } from "lucide-react";
import { supabase } from "../../lib/supabase";
import type { Tag } from "../../types";
import { TagBadge } from "./TagBadge";

const RANDOM_COLORS = [
  "#e63946", "#457b9d", "#2a9d8f", "#e9c46a", "#f4a261",
  "#264653", "#6a4c93", "#1982c4", "#8ac926", "#ff595e",
  "#6d6875", "#b5838d", "#ffb703", "#023047", "#fb8500",
];

function getRandomColor(): string {
  return RANDOM_COLORS[Math.floor(Math.random() * RANDOM_COLORS.length)];
}

interface TagSelectorProps {
  selectedIds: number[];
  onChange: (ids: number[]) => void;
}

export function TagSelector({ selectedIds, onChange }: TagSelectorProps) {
  const queryClient = useQueryClient();
  const [isCreating, setIsCreating] = useState(false);
  const [newTagName, setNewTagName] = useState("");

  const { data: tags = [], isLoading } = useQuery<Tag[]>({
    queryKey: ["tags", "list"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("tags")
        .select("*")
        .order("name");
      if (error) throw error;
      return data as Tag[];
    },
  });

  const createTag = useMutation({
    mutationFn: async (tag: { name: string; color: string }) => {
      const { data, error } = await supabase
        .from("tags")
        .insert(tag)
        .select()
        .single();
      if (error) throw error;
      return data as Tag;
    },
    onSuccess: (newTag) => {
      queryClient.invalidateQueries({ queryKey: ["tags"] });
      onChange([...selectedIds, newTag.id]);
      setNewTagName("");
      setIsCreating(false);
    },
  });

  function toggleTag(tagId: number) {
    if (selectedIds.includes(tagId)) {
      onChange(selectedIds.filter((id) => id !== tagId));
    } else {
      onChange([...selectedIds, tagId]);
    }
  }

  function handleCreateSubmit() {
    const name = newTagName.trim();
    if (!name) return;
    createTag.mutate({ name, color: getRandomColor() });
  }

  if (isLoading) {
    return (
      <div className="flex gap-2 overflow-x-auto py-1">
        {[1, 2, 3].map((i) => (
          <div
            key={i}
            className="h-7 w-16 rounded-full bg-[var(--bg-muted)] animate-pulse shrink-0"
          />
        ))}
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2 overflow-x-auto py-1 scrollbar-hide">
      {tags.map((tag) => {
        const isSelected = selectedIds.includes(tag.id);
        return (
          <div key={tag.id} className="shrink-0">
            <TagBadge
              tag={tag}
              size="md"
              selected={isSelected}
              outline={!isSelected}
              onClick={() => toggleTag(tag.id)}
            />
          </div>
        );
      })}

      {isCreating ? (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            handleCreateSubmit();
          }}
          className="flex items-center gap-1 shrink-0"
        >
          <input
            autoFocus
            type="text"
            value={newTagName}
            onChange={(e) => setNewTagName(e.target.value)}
            onBlur={() => {
              if (!newTagName.trim()) setIsCreating(false);
            }}
            onKeyDown={(e) => {
              if (e.key === "Escape") {
                setNewTagName("");
                setIsCreating(false);
              }
            }}
            placeholder="Tag name..."
            className="h-7 w-24 rounded-full border border-[var(--border-color)] bg-[var(--bg-primary)] px-3 text-xs text-[var(--text-primary)] placeholder:text-[var(--text-muted)] focus:outline-none focus:ring-1 focus:ring-[var(--gold)]"
            disabled={createTag.isPending}
          />
        </form>
      ) : (
        <button
          type="button"
          onClick={() => setIsCreating(true)}
          className="flex items-center gap-1 shrink-0 rounded-full border border-dashed border-[var(--border-color)] px-3 py-1 text-xs text-[var(--text-muted)] hover:border-[var(--gold)] hover:text-[var(--gold)] transition-colors"
        >
          <Plus size={12} />
          Add Tag
        </button>
      )}
    </div>
  );
}
