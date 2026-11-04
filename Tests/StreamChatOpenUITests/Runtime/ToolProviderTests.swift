//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

@Suite("Tool providers")
struct ToolProviderTests {
    struct StubClient: MCPClient {
        let result: MCPToolResult

        func callTool(name: String, arguments: OpenUIObject) async throws -> MCPToolResult {
            result
        }
    }

    @Test func functionProviderCallsTheToolsHandler() async throws {
        let provider = FunctionToolProvider([
            "echo": { arguments in .object(arguments) },
            "other": { _ in .null }
        ])

        let value = try await provider.callTool("echo", arguments: ["city": "Ohrid"])

        #expect(value == ["city": "Ohrid"])
    }

    @Test func functionProviderThrowsForAnUnknownTool() async {
        let provider = FunctionToolProvider(["echo": { _ in .null }, "list": { _ in .null }])

        await #expect(throws: ToolNotFoundError(toolName: "missing", availableTools: ["echo", "list"])) {
            try await provider.callTool("missing", arguments: [:])
        }
    }

    @Test func toolNotFoundErrorNamesTheAvailableTools() {
        #expect(ToolNotFoundError(toolName: "a", availableTools: ["b", "c"]).errorDescription == #"[openui] No handler for tool "a". Available: b, c"#)
        #expect(ToolNotFoundError(toolName: "a").errorDescription == #"[openui] No handler for tool "a". Available: (none)"#)
    }

    @Test func mcpResultPrefersStructuredContent() throws {
        let result = MCPToolResult(content: [.init(type: "text", text: "ignored")], structuredContent: ["rows": [1]])

        #expect(try result.extractedValue() == ["rows": [1]])
    }

    @Test func mcpResultParsesJSONText() throws {
        let result = MCPToolResult(content: [.init(type: "text", text: #"{"rows":"#), .init(type: "image"), .init(type: "text", text: "[2]}")])

        #expect(try result.extractedValue() == ["rows": [2]])
    }

    @Test func mcpResultFallsBackToRawText() throws {
        #expect(try MCPToolResult(content: [.init(type: "text", text: "plain")]).extractedValue() == "plain")
        #expect(try MCPToolResult(content: []).extractedValue() == .null)
    }

    @Test func mcpErrorResultThrows() {
        let result = MCPToolResult(content: [.init(type: "text", text: "boom"), .init(type: "text", text: "again")], isError: true)

        #expect(throws: MCPToolError("boom\nagain")) {
            try result.extractedValue()
        }
        #expect(MCPToolError("").errorDescription == "MCP tool error: Unknown error")
        #expect(MCPToolError("boom").errorDescription == "MCP tool error: boom")
    }

    @Test func mcpProviderReturnsTheExtractedValue() async throws {
        let provider = MCPToolProvider(client: StubClient(result: MCPToolResult(content: [.init(type: "text", text: "[1,2]")])))

        #expect(try await provider.callTool("list", arguments: [:]) == [1, 2])
    }
}
