import XCTest
@testable import CommandPocket

final class NamingServiceTests: XCTestCase {
    func testCommonCommandNames() {
        XCTAssertEqual(NamingService.suggestName(for: "git status"), "查看 Git 状态")
        XCTAssertEqual(NamingService.suggestName(for: "go mod tidy"), "整理 Go 依赖")
        XCTAssertEqual(NamingService.suggestName(for: "npm run dev"), "启动前端开发环境")
        XCTAssertEqual(NamingService.suggestName(for: "kinit user@REALM"), "刷新 Kerberos")
    }

    func testGroups() {
        XCTAssertEqual(NamingService.suggestGroup(for: "ssh dev"), "服务器")
        XCTAssertEqual(NamingService.suggestGroup(for: "curl https://example.com"), "网络")
        XCTAssertEqual(NamingService.suggestGroup(for: "tail -f app.log"), "日志")
    }

    func testSensitiveContent() {
        XCTAssertNotNil(NamingService.sensitiveReason(for: "Authorization: Bearer secret"))
        XCTAssertNotNil(NamingService.sensitiveReason(for: "-----BEGIN PRIVATE KEY-----"))
        XCTAssertNil(NamingService.sensitiveReason(for: "git status"))
    }
}

