import { describe, expect, it } from "vitest";
import { sensitiveReason, suggestGroup, suggestName } from "./naming-service";

describe("naming service", () => {
  it("names common commands", () => {
    expect(suggestName("git status")).toBe("查看 Git 状态");
    expect(suggestName("go mod tidy")).toBe("整理 Go 依赖");
    expect(suggestName("npm run dev")).toBe("启动前端开发环境");
    expect(suggestName("kinit user@REALM")).toBe("刷新 Kerberos");
  });

  it("suggests groups", () => {
    expect(suggestGroup("ssh dev")).toBe("服务器");
    expect(suggestGroup("curl https://example.com")).toBe("网络");
    expect(suggestGroup("tail -f app.log")).toBe("日志");
  });

  it("blocks sensitive values", () => {
    expect(sensitiveReason("Authorization: Bearer secret")).not.toBeNull();
    expect(sensitiveReason("-----BEGIN PRIVATE KEY-----")).not.toBeNull();
    expect(sensitiveReason("git status")).toBeNull();
  });
});

