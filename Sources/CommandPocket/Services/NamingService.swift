import Foundation

enum NamingService {
    static func suggestName(for rawCommand: String) -> String {
        let command = normalized(rawCommand)
        let words = command.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let executable = words.first?.lowercased() else { return "常用命令" }

        switch executable {
        case "git":
            return gitName(words)
        case "go":
            if words.dropFirst().starts(with: ["mod", "tidy"]) { return "整理 Go 依赖" }
            if words.dropFirst().first == "version" { return "查看 Go 版本" }
            if words.dropFirst().first == "test" { return "运行 Go 测试" }
            return "执行 Go 命令"
        case "npm", "pnpm", "yarn", "bun":
            if words.contains("dev") { return "启动前端开发环境" }
            if words.contains("test") { return "运行前端测试" }
            if words.contains("build") { return "构建前端项目" }
            return "执行 \(executable) 命令"
        case "ssh":
            let host = sshHost(words)
            return host.map { "连接 \($0) 开发机" } ?? "连接开发机"
        case "kinit":
            return "刷新 Kerberos"
        case "curl":
            return curlName(words)
        case "tail":
            return words.contains("-f") ? "实时查看日志" : "查看日志"
        case "docker":
            if words.dropFirst().first == "ps" { return "查看 Docker 容器" }
            return "执行 Docker 命令"
        case "kubectl":
            if words.dropFirst().first == "get" { return "查看 Kubernetes 资源" }
            return "执行 kubectl 命令"
        default:
            return "\(executable) 常用命令"
        }
    }

    static func suggestGroup(for rawCommand: String) -> String {
        let executable = normalized(rawCommand)
            .split(whereSeparator: \.isWhitespace)
            .first?
            .lowercased() ?? ""

        switch executable {
        case "git": return "Git"
        case "go": return "Go"
        case "npm", "pnpm", "yarn", "bun": return "前端"
        case "ssh", "scp", "rsync": return "服务器"
        case "curl", "wget": return "网络"
        case "tail", "less", "grep", "rg": return "日志"
        case "docker", "kubectl": return "容器"
        case "kinit", "klist": return "认证"
        default: return "其他"
        }
    }

    static func sensitiveReason(for rawCommand: String) -> String? {
        let lower = rawCommand.lowercased()
        if lower.contains("begin private key") { return "检测到私钥内容，不能保存" }
        if lower.contains("cookie:") || lower.contains("user_token=") {
            return "检测到 Cookie 或用户令牌，不能保存"
        }
        if lower.contains("bearer ") || lower.contains("eyj") {
            return "检测到 Token，不能保存"
        }
        if lower.contains("--password") || lower.contains("passwd=") {
            return "检测到密码参数，请移除后再保存"
        }
        return nil
    }

    private static func normalized(_ command: String) -> String {
        command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private static func gitName(_ words: [String]) -> String {
        guard words.count > 1 else { return "执行 Git 命令" }
        switch words[1] {
        case "status": return "查看 Git 状态"
        case "pull":
            if let branch = words.last, !branch.hasPrefix("-"), branch != "pull" {
                return "拉取 \(branch) 最新代码"
            }
            return "拉取最新代码"
        case "push": return "推送 Git 代码"
        case "checkout", "switch": return "切换 Git 分支"
        case "log": return "查看 Git 提交记录"
        default: return "执行 Git \(words[1])"
        }
    }

    private static func sshHost(_ words: [String]) -> String? {
        guard words.count > 1 else { return nil }
        var index = words.count - 1
        while index > 0 {
            let word = words[index]
            if !word.hasPrefix("-"), !word.contains(":"), Int(word) == nil {
                return word.split(separator: "@").last.map(String.init)
            }
            index -= 1
        }
        return nil
    }

    private static func curlName(_ words: [String]) -> String {
        for word in words.reversed() {
            guard word.hasPrefix("http"),
                  let host = URL(string: word)?.host
            else { continue }
            return "请求 \(host) 接口"
        }
        return "请求接口"
    }
}

