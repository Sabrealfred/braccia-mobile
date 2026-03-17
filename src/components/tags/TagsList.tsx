import { useQuery } from "@tanstack/react-query";
import { supabase } from "../../lib/supabase";
import type { Tag } from "../../types";
import { TagBadge } from "./TagBadge";

interface TagsListProps {
  tagIds: number[];
}

export function TagsList({ tagIds }: TagsListProps) {
  const { data: tags = [] } = useQuery<Tag[]>({
    queryKey: ["tags", "byIds", tagIds],
    queryFn: async () => {
      if (tagIds.length === 0) return [];
      const { data, error } = await supabase
        .from("tags")
        .select("*")
        .in("id", tagIds);
      if (error) throw error;
      return data as Tag[];
    },
    enabled: tagIds.length > 0,
  });

  if (tags.length === 0) return null;

  return (
    <div className="flex flex-wrap gap-1">
      {tags.map((tag) => (
        <TagBadge key={tag.id} tag={tag} size="sm" />
      ))}
    </div>
  );
}
