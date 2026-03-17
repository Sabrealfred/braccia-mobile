import { cn, getInitials, hashString } from "../../lib/utils";

const avatarColors = [
  "var(--avatar-0)",
  "var(--avatar-1)",
  "var(--avatar-2)",
  "var(--avatar-3)",
  "var(--avatar-4)",
  "var(--avatar-5)",
  "var(--avatar-6)",
  "var(--avatar-7)",
  "var(--avatar-8)",
  "var(--avatar-9)",
];

interface AvatarProps {
  firstName: string;
  lastName: string;
  src?: string;
  size?: "sm" | "md" | "lg" | "xl";
  className?: string;
}

const sizeMap = {
  sm: "w-8 h-8 text-xs",
  md: "w-10 h-10 text-sm",
  lg: "w-12 h-12 text-base",
  xl: "w-16 h-16 text-lg",
};

export function Avatar({
  firstName,
  lastName,
  src,
  size = "md",
  className,
}: AvatarProps) {
  const initials = getInitials(firstName, lastName);
  const color =
    avatarColors[hashString(`${firstName}${lastName}`) % avatarColors.length];

  if (src) {
    return (
      <img
        src={src}
        alt={`${firstName} ${lastName}`}
        className={cn("rounded-full object-cover", sizeMap[size], className)}
      />
    );
  }

  return (
    <div
      className={cn(
        "rounded-full flex items-center justify-center font-semibold text-white shrink-0",
        sizeMap[size],
        className
      )}
      style={{ background: color }}
    >
      {initials}
    </div>
  );
}
