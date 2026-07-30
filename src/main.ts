import "./style.css";
import {
  loadCommands,
  makeCommand,
  saveCommands,
  sortedCommands
} from "./command-store";
import { sensitiveReason, suggestGroup, suggestName } from "./naming-service";
import {
  readClipboard,
  registerShortcuts,
  setWindowExpanded,
  startWindowDrag,
  writeClipboard
} from "./platform";
import type { ViewMode } from "./types";

const app = document.querySelector<HTMLDivElement>("#app") as HTMLDivElement;
if (!app) throw new Error("App root not found");

let commands = loadCommands();
let expanded = false;
let mode: ViewMode = "list";
let toastTimer: number | undefined;

const icons: Record<string, string> = {
  Git: "⑂",
  Go: "◫",
  前端: "{ }",
  服务器: "▤",
  网络: "◎",
  日志: "≡",
  认证: "⌑",
  容器: "◇",
  其他: ">_"
};

function render(): void {
  app.className = expanded ? "expanded" : "collapsed";
  app.innerHTML = expanded ? renderPanel() : renderLauncher();
  bindEvents();
}

function renderLauncher(): string {
  return `
    <button class="launcher" id="launcher" aria-label="展开命令口袋">
      <span class="terminal-icon">&gt;_</span>
      <span class="launcher-chevron">⌄</span>
    </button>
  `;
}

function renderPanel(): string {
  return `
    <main class="panel">
      <header class="panel-header" id="drag-handle">
        <div>
          <h1>${mode === "list" ? "命令口袋" : "快速添加"}</h1>
          <p>${mode === "list" ? "点击一行即可复制" : "从剪贴板保存命令"}</p>
        </div>
        <div class="header-actions">
          ${mode === "list"
            ? `<span class="shortcut">⌥ Space</span>
               <button class="primary small" id="quick-add">＋ 快速添加</button>`
            : `<button class="secondary small" id="back">返回</button>`}
          <button class="icon-button" id="collapse" aria-label="收起">⌃</button>
        </div>
      </header>
      ${mode === "list" ? renderList() : renderAddForm()}
      <div class="toast" id="toast" role="status" aria-live="polite"></div>
    </main>
  `;
}

function renderList(): string {
  const items = sortedCommands(commands);
  if (items.length === 0) {
    return `
      <section class="empty">
        <div class="empty-icon">&gt;_</div>
        <h2>还没有保存命令</h2>
        <p>复制一条命令，然后按 ⌥⇧Space 快速添加。</p>
        <button class="primary" id="empty-add">添加第一条命令</button>
      </section>
    `;
  }

  return `
    <section class="command-list" aria-label="常用命令">
      ${items.map(item => `
        <article class="command-row" data-id="${item.id}">
          <button class="command-copy" data-copy="${item.id}">
            <span class="group-icon">${icons[item.group] ?? icons.其他}</span>
            <span class="command-content">
              <span class="command-title">
                ${escapeHtml(item.name)}
                ${item.isPinned ? '<span class="pin">◆</span>' : ""}
              </span>
              <code>${escapeHtml(item.command)}</code>
            </span>
            <span class="copy-mark">▣</span>
          </button>
          <div class="row-actions">
            <button data-pin="${item.id}">${item.isPinned ? "取消置顶" : "置顶"}</button>
            <button class="danger" data-delete="${item.id}">删除</button>
          </div>
        </article>
      `).join("")}
    </section>
    <footer class="panel-footer">
      <span>拖动顶部调整位置</span>
      <span>⌥⇧Space 快速添加</span>
    </footer>
  `;
}

function renderAddForm(): string {
  return `
    <form class="add-form" id="add-form">
      <label>
        <span>命令</span>
        <textarea id="command-input" placeholder="粘贴或输入命令" required></textarea>
      </label>
      <label>
        <span>名称</span>
        <div class="inline-field">
          <input id="name-input" placeholder="自动生成名称" required />
          <button class="secondary small" id="auto-name" type="button">✦ 自动命名</button>
        </div>
      </label>
      <label>
        <span>分组</span>
        <select id="group-input">
          ${["Git", "Go", "前端", "服务器", "网络", "日志", "认证", "容器", "其他"]
            .map(group => `<option value="${group}">${group}</option>`)
            .join("")}
        </select>
      </label>
      <p class="validation" id="validation"></p>
      <div class="form-actions">
        <button class="secondary" id="cancel-add" type="button">取消</button>
        <button class="primary" type="submit">保存命令 ↵</button>
      </div>
    </form>
  `;
}

function bindEvents(): void {
  document.querySelector("#launcher")?.addEventListener("click", togglePanel);
  document.querySelector("#collapse")?.addEventListener("click", togglePanel);
  document.querySelector("#quick-add")?.addEventListener("click", openQuickAdd);
  document.querySelector("#empty-add")?.addEventListener("click", openQuickAdd);
  document.querySelector("#back")?.addEventListener("click", showList);
  document.querySelector("#cancel-add")?.addEventListener("click", showList);
  document.querySelector("#drag-handle")?.addEventListener("mousedown", event => {
    if ((event.target as HTMLElement).closest("button")) return;
    void startWindowDrag();
  });

  document.querySelectorAll<HTMLButtonElement>("[data-copy]").forEach(button => {
    button.addEventListener("click", () => void copyCommand(button.dataset.copy ?? ""));
  });
  document.querySelectorAll<HTMLButtonElement>("[data-pin]").forEach(button => {
    button.addEventListener("click", () => togglePin(button.dataset.pin ?? ""));
  });
  document.querySelectorAll<HTMLButtonElement>("[data-delete]").forEach(button => {
    button.addEventListener("click", () => deleteCommand(button.dataset.delete ?? ""));
  });

  const commandInput = document.querySelector<HTMLTextAreaElement>("#command-input");
  commandInput?.addEventListener("input", fillSuggestions);
  document.querySelector("#auto-name")?.addEventListener("click", fillSuggestions);
  document.querySelector<HTMLFormElement>("#add-form")?.addEventListener("submit", saveNewCommand);

  if (mode === "add") void hydrateQuickAdd();
}

async function togglePanel(): Promise<void> {
  expanded = !expanded;
  if (!expanded) mode = "list";
  await setWindowExpanded(expanded);
  render();
}

async function openQuickAdd(): Promise<void> {
  if (!expanded) {
    expanded = true;
    await setWindowExpanded(true);
  }
  mode = "add";
  render();
}

function showList(): void {
  mode = "list";
  render();
}

async function hydrateQuickAdd(): Promise<void> {
  const commandInput = document.querySelector<HTMLTextAreaElement>("#command-input");
  if (!commandInput || commandInput.value) return;
  commandInput.value = await readClipboard();
  fillSuggestions();
  document.querySelector<HTMLInputElement>("#name-input")?.focus();
}

function fillSuggestions(): void {
  const command = document.querySelector<HTMLTextAreaElement>("#command-input")?.value ?? "";
  const nameInput = document.querySelector<HTMLInputElement>("#name-input");
  const groupInput = document.querySelector<HTMLSelectElement>("#group-input");
  if (nameInput) nameInput.value = suggestName(command);
  if (groupInput) groupInput.value = suggestGroup(command);
}

function saveNewCommand(event: SubmitEvent): void {
  event.preventDefault();
  const command = document.querySelector<HTMLTextAreaElement>("#command-input")?.value.trim() ?? "";
  const name = document.querySelector<HTMLInputElement>("#name-input")?.value.trim() ?? "";
  const group = document.querySelector<HTMLSelectElement>("#group-input")?.value ?? "其他";
  const validation = document.querySelector<HTMLParagraphElement>("#validation");

  if (!command) {
    if (validation) validation.textContent = "请输入要保存的命令";
    return;
  }
  const reason = sensitiveReason(command);
  if (reason) {
    if (validation) validation.textContent = reason;
    return;
  }

  commands.push(
    makeCommand(name || suggestName(command), command, group, commands.length)
  );
  persist();
  mode = "list";
  render();
  showToast("命令已保存");
}

async function copyCommand(id: string): Promise<void> {
  const item = commands.find(command => command.id === id);
  if (!item) return;
  await writeClipboard(item.command);
  showToast(`已复制：${item.name}`);
}

function togglePin(id: string): void {
  commands = commands.map(item =>
    item.id === id
      ? { ...item, isPinned: !item.isPinned, updatedAt: new Date().toISOString() }
      : item
  );
  persist();
  render();
}

function deleteCommand(id: string): void {
  commands = commands.filter(item => item.id !== id);
  persist();
  render();
}

function persist(): void {
  saveCommands(commands);
}

function showToast(message: string): void {
  const toast = document.querySelector<HTMLDivElement>("#toast");
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add("visible");
  window.clearTimeout(toastTimer);
  toastTimer = window.setTimeout(() => toast.classList.remove("visible"), 1500);
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

document.addEventListener("keydown", event => {
  if (event.key === "Escape" && expanded) void togglePanel();
});

void registerShortcuts(
  () => void togglePanel(),
  () => void openQuickAdd()
).catch(error => console.warn("快捷键注册失败", error));

render();
