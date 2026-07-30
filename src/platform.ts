import { readText, writeText } from "@tauri-apps/plugin-clipboard-manager";
import { register, unregisterAll } from "@tauri-apps/plugin-global-shortcut";
import {
  getCurrentWindow,
  LogicalPosition,
  LogicalSize
} from "@tauri-apps/api/window";

const isTauri = (): boolean => "__TAURI_INTERNALS__" in window;

export async function readClipboard(): Promise<string> {
  if (isTauri()) return readText();
  return navigator.clipboard?.readText().catch(() => "") ?? "";
}

export async function writeClipboard(text: string): Promise<void> {
  if (isTauri()) {
    await writeText(text);
    return;
  }
  await navigator.clipboard.writeText(text);
}

export async function setWindowExpanded(expanded: boolean): Promise<void> {
  if (!isTauri()) return;
  const window = getCurrentWindow();
  const position = await window.outerPosition();
  const scale = await window.scaleFactor();
  const oldWidth = expanded ? 48 : 380;
  const newWidth = expanded ? 380 : 48;
  const offset = (newWidth - oldWidth) * scale;

  await window.setSize(new LogicalSize(newWidth, expanded ? 520 : 48));
  await window.setPosition(
    new LogicalPosition(
      Math.max(0, position.x / scale - offset / scale),
      position.y / scale
    )
  );
  if (expanded) await window.setFocus();
}

export async function startWindowDrag(): Promise<void> {
  if (isTauri()) await getCurrentWindow().startDragging();
}

export async function registerShortcuts(
  onToggle: () => void,
  onQuickAdd: () => void
): Promise<void> {
  if (!isTauri()) return;
  await unregisterAll();
  await register("Alt+Space", event => {
    if (event.state === "Pressed") onToggle();
  });
  await register("Alt+Shift+Space", event => {
    if (event.state === "Pressed") onQuickAdd();
  });
}

