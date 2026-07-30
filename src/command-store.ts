import type { CommandItem } from "./types";

const STORAGE_KEY = "command-pocket.commands.v2";

const defaults: CommandItem[] = [
  makeCommand("查看 Git 状态", "git status", "Git", 0),
  makeCommand("整理 Go 依赖", "go mod tidy", "Go", 1),
  makeCommand("启动前端开发环境", "npm run dev", "前端", 2),
  makeCommand("查看实时日志", "tail -f app.log", "日志", 3)
];

export function loadCommands(): CommandItem[] {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (!saved) return defaults;

  try {
    const commands = JSON.parse(saved) as CommandItem[];
    return Array.isArray(commands) ? commands : defaults;
  } catch {
    return defaults;
  }
}

export function saveCommands(commands: CommandItem[]): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(commands));
}

export function sortedCommands(commands: CommandItem[]): CommandItem[] {
  return [...commands].sort((left, right) => {
    if (left.isPinned !== right.isPinned) return left.isPinned ? -1 : 1;
    if (left.sortOrder !== right.sortOrder) return left.sortOrder - right.sortOrder;
    return right.updatedAt.localeCompare(left.updatedAt);
  });
}

export function makeCommand(
  name: string,
  command: string,
  group: string,
  sortOrder: number
): CommandItem {
  const now = new Date().toISOString();
  return {
    id: crypto.randomUUID(),
    name,
    command,
    group,
    isPinned: false,
    sortOrder,
    createdAt: now,
    updatedAt: now
  };
}

