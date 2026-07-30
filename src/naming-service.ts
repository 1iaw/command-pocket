const normalize = (command: string): string => command.trim().replace(/\s+/g, " ");

const wordsOf = (command: string): string[] => normalize(command).split(" ").filter(Boolean);

export function suggestName(rawCommand: string): string {
  const words = wordsOf(rawCommand);
  const executable = words[0]?.toLowerCase();
  if (!executable) return "常用命令";

  switch (executable) {
    case "git":
      return gitName(words);
    case "go":
      if (words[1] === "mod" && words[2] === "tidy") return "整理 Go 依赖";
      if (words[1] === "version") return "查看 Go 版本";
      if (words[1] === "test") return "运行 Go 测试";
      return "执行 Go 命令";
    case "npm":
    case "pnpm":
    case "yarn":
    case "bun":
      if (words.includes("dev")) return "启动前端开发环境";
      if (words.includes("test")) return "运行前端测试";
      if (words.includes("build")) return "构建前端项目";
      return `执行 ${executable} 命令`;
    case "ssh": {
      const host = sshHost(words);
      return host ? `连接 ${host} 开发机` : "连接开发机";
    }
    case "kinit":
      return "刷新 Kerberos";
    case "curl":
      return curlName(words);
    case "tail":
      return words.includes("-f") ? "实时查看日志" : "查看日志";
    case "docker":
      return words[1] === "ps" ? "查看 Docker 容器" : "执行 Docker 命令";
    case "kubectl":
      return words[1] === "get" ? "查看 Kubernetes 资源" : "执行 kubectl 命令";
    default:
      return `${executable} 常用命令`;
  }
}

export function suggestGroup(rawCommand: string): string {
  const executable = wordsOf(rawCommand)[0]?.toLowerCase() ?? "";
  if (executable === "git") return "Git";
  if (executable === "go") return "Go";
  if (["npm", "pnpm", "yarn", "bun"].includes(executable)) return "前端";
  if (["ssh", "scp", "rsync"].includes(executable)) return "服务器";
  if (["curl", "wget"].includes(executable)) return "网络";
  if (["tail", "less", "grep", "rg"].includes(executable)) return "日志";
  if (["docker", "kubectl"].includes(executable)) return "容器";
  if (["kinit", "klist"].includes(executable)) return "认证";
  return "其他";
}

export function sensitiveReason(rawCommand: string): string | null {
  const lower = rawCommand.toLowerCase();
  if (lower.includes("begin private key")) return "检测到私钥内容，不能保存";
  if (lower.includes("cookie:") || lower.includes("user_token=")) {
    return "检测到 Cookie 或用户令牌，不能保存";
  }
  if (lower.includes("bearer ") || lower.includes("eyj")) {
    return "检测到 Token，不能保存";
  }
  if (lower.includes("--password") || lower.includes("passwd=")) {
    return "检测到密码参数，请移除后再保存";
  }
  return null;
}

function gitName(words: string[]): string {
  switch (words[1]) {
    case "status":
      return "查看 Git 状态";
    case "pull": {
      const branch = words.at(-1);
      return branch && branch !== "pull" && !branch.startsWith("-")
        ? `拉取 ${branch} 最新代码`
        : "拉取最新代码";
    }
    case "push":
      return "推送 Git 代码";
    case "checkout":
    case "switch":
      return "切换 Git 分支";
    case "log":
      return "查看 Git 提交记录";
    default:
      return words[1] ? `执行 Git ${words[1]}` : "执行 Git 命令";
  }
}

function sshHost(words: string[]): string | null {
  for (let index = words.length - 1; index > 0; index -= 1) {
    const word = words[index];
    if (!word.startsWith("-") && !word.includes(":") && !/^\d+$/.test(word)) {
      return word.split("@").at(-1) ?? null;
    }
  }
  return null;
}

function curlName(words: string[]): string {
  for (const word of [...words].reverse()) {
    if (!word.startsWith("http")) continue;
    try {
      return `请求 ${new URL(word).host} 接口`;
    } catch {
      continue;
    }
  }
  return "请求接口";
}

