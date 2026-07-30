export interface CommandItem {
  id: string;
  name: string;
  command: string;
  group: string;
  isPinned: boolean;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}

export type ViewMode = "list" | "add";

