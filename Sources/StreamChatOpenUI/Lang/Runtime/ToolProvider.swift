//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Executes the tools referenced by `Query(...)` and `Mutation(...)` statements.
///
/// Works with any backend (REST, GraphQL, MCP, local functions). The renderer calls the provider
/// when queries load or refresh, and when an `Action` runs a mutation.
@available(iOS 17.0, macOS 14.0, *)
protocol OpenUIToolProvider: Sendable {
    func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue

    /// Runs a tool, saying whether the person asked for it: a `Mutation` runs from a tap, while a
    /// `Query` runs by itself as the UI shows. It runs `callTool(_:arguments:)` by default.
    func callTool(_ name: String, arguments: OpenUIObject, userInitiated: Bool) async throws -> OpenUIValue

    /// The shortest time between two refreshes of a query, in seconds. The model writes a query's
    /// refresh interval, so a shorter one waits this long. Five seconds by default.
    var minimumRefreshInterval: TimeInterval { get }
}

@available(iOS 17.0, macOS 14.0, *)
extension OpenUIToolProvider {
    var minimumRefreshInterval: TimeInterval { 5 }

    func callTool(_ name: String, arguments: OpenUIObject, userInitiated: Bool) async throws -> OpenUIValue {
        try await callTool(name, arguments: arguments)
    }
}

/// Thrown when a function-map provider has no handler for a tool.
@available(iOS 17.0, macOS 14.0, *)
struct ToolNotFoundError: Error, LocalizedError, Sendable, Equatable {
    let toolName: String
    let availableTools: [String]

    init(toolName: String, availableTools: [String] = []) {
        self.toolName = toolName
        self.availableTools = availableTools
    }

    var errorDescription: String? {
        let available = availableTools.isEmpty ? "(none)" : availableTools.joined(separator: ", ")
        return "[openui] No handler for tool \"\(toolName)\". Available: \(available)"
    }
}

/// Thrown when an MCP tool call returns `isError: true`.
@available(iOS 17.0, macOS 14.0, *)
struct MCPToolError: Error, LocalizedError, Sendable, Equatable {
    let toolErrorText: String

    init(_ toolErrorText: String) {
        self.toolErrorText = toolErrorText
    }

    var errorDescription: String? {
        "MCP tool error: \(toolErrorText.isEmpty ? "Unknown error" : toolErrorText)"
    }
}

/// A tool provider backed by a map of async functions.
///
/// ```swift
/// let tools = FunctionToolProvider([
///     "search_hotels": { args in try await api.searchHotels(args) },
/// ])
/// ```
@available(iOS 17.0, macOS 14.0, *)
struct FunctionToolProvider: OpenUIToolProvider {
    typealias Handler = @Sendable (OpenUIObject) async throws -> OpenUIValue

    let minimumRefreshInterval: TimeInterval
    private let names: [String]
    private let handlers: [String: Handler]

    /// - Parameters:
    ///   - handlers: The tools, by name.
    ///   - minimumRefreshInterval: The shortest time between two refreshes of a query, in seconds.
    init(_ handlers: KeyValuePairs<String, Handler>, minimumRefreshInterval: TimeInterval = 5) {
        var names: [String] = []
        var map: [String: Handler] = [:]
        for (name, handler) in handlers {
            if map.updateValue(handler, forKey: name) == nil { names.append(name) }
        }
        self.names = names
        self.handlers = map
        self.minimumRefreshInterval = minimumRefreshInterval
    }

    func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue {
        guard let handler = handlers[name] else {
            throw ToolNotFoundError(toolName: name, availableTools: names)
        }
        return try await handler(arguments)
    }
}

// MARK: - MCP

/// The result envelope of an MCP `tools/call` request.
@available(iOS 17.0, macOS 14.0, *)
struct MCPToolResult: Sendable, Hashable {
    struct Content: Sendable, Hashable {
        var type: String
        var text: String?

        init(type: String, text: String? = nil) {
            self.type = type
            self.text = text
        }
    }

    var content: [Content]
    var structuredContent: OpenUIValue?
    var isError: Bool

    init(content: [Content], structuredContent: OpenUIValue? = nil, isError: Bool = false) {
        self.content = content
        self.structuredContent = structuredContent
        self.isError = isError
    }

    /// Extracts the tool's data: prefers `structuredContent`, then JSON-parses the text content
    /// (falling back to the raw text). Throws ``MCPToolError`` for error results.
    func extractedValue() throws -> OpenUIValue {
        let texts = content.filter { $0.type == "text" }.map { $0.text ?? "" }
        if isError {
            throw MCPToolError(texts.joined(separator: "\n"))
        }
        if let structuredContent, !structuredContent.isNull {
            return structuredContent
        }
        guard !texts.isEmpty else { return .null }
        let text = texts.joined()
        return (try? OpenUIJSON.parse(text)) ?? .string(text)
    }
}

/// Minimal MCP client shape (any MCP SDK client can be adapted to it).
@available(iOS 17.0, macOS 14.0, *)
protocol MCPClient: Sendable {
    func callTool(name: String, arguments: OpenUIObject) async throws -> MCPToolResult
}

/// Adapts an ``MCPClient`` to ``OpenUIToolProvider``.
@available(iOS 17.0, macOS 14.0, *)
struct MCPToolProvider: OpenUIToolProvider {
    let client: any MCPClient

    init(client: any MCPClient) {
        self.client = client
    }

    func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue {
        try await client.callTool(name: name, arguments: arguments).extractedValue()
    }
}
