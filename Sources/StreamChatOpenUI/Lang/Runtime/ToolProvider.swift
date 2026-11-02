//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Executes the tools referenced by `Query(...)` and `Mutation(...)` statements.
///
/// Works with any backend (REST, GraphQL, MCP, local functions). The renderer calls the provider
/// when queries load or refresh, and when an `Action` runs a mutation.
@available(iOS 17.0, macOS 14.0, *)
public protocol OpenUIToolProvider: Sendable {
    func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue
}

/// Thrown when a function-map provider has no handler for a tool.
@available(iOS 17.0, macOS 14.0, *)
public struct ToolNotFoundError: Error, LocalizedError, Sendable, Equatable {
    public let toolName: String
    public let availableTools: [String]

    public init(toolName: String, availableTools: [String] = []) {
        self.toolName = toolName
        self.availableTools = availableTools
    }

    public var errorDescription: String? {
        let available = availableTools.isEmpty ? "(none)" : availableTools.joined(separator: ", ")
        return "[openui] No handler for tool \"\(toolName)\". Available: \(available)"
    }
}

/// Thrown when an MCP tool call returns `isError: true`.
@available(iOS 17.0, macOS 14.0, *)
public struct MCPToolError: Error, LocalizedError, Sendable, Equatable {
    public let toolErrorText: String

    public init(_ toolErrorText: String) {
        self.toolErrorText = toolErrorText
    }

    public var errorDescription: String? {
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
public struct FunctionToolProvider: OpenUIToolProvider {
    public typealias Handler = @Sendable (OpenUIObject) async throws -> OpenUIValue

    private let names: [String]
    private let handlers: [String: Handler]

    public init(_ handlers: KeyValuePairs<String, Handler>) {
        var names: [String] = []
        var map: [String: Handler] = [:]
        for (name, handler) in handlers {
            if map.updateValue(handler, forKey: name) == nil { names.append(name) }
        }
        self.names = names
        self.handlers = map
    }

    public func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue {
        guard let handler = handlers[name] else {
            throw ToolNotFoundError(toolName: name, availableTools: names)
        }
        return try await handler(arguments)
    }
}

// MARK: - MCP

/// The result envelope of an MCP `tools/call` request.
@available(iOS 17.0, macOS 14.0, *)
public struct MCPToolResult: Sendable, Hashable {
    public struct Content: Sendable, Hashable {
        public var type: String
        public var text: String?

        public init(type: String, text: String? = nil) {
            self.type = type
            self.text = text
        }
    }

    public var content: [Content]
    public var structuredContent: OpenUIValue?
    public var isError: Bool

    public init(content: [Content], structuredContent: OpenUIValue? = nil, isError: Bool = false) {
        self.content = content
        self.structuredContent = structuredContent
        self.isError = isError
    }

    /// Extracts the tool's data: prefers `structuredContent`, then JSON-parses the text content
    /// (falling back to the raw text). Throws ``MCPToolError`` for error results.
    public func extractedValue() throws -> OpenUIValue {
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
public protocol MCPClient: Sendable {
    func callTool(name: String, arguments: OpenUIObject) async throws -> MCPToolResult
}

/// Adapts an ``MCPClient`` to ``OpenUIToolProvider``.
@available(iOS 17.0, macOS 14.0, *)
public struct MCPToolProvider: OpenUIToolProvider {
    public let client: any MCPClient

    public init(client: any MCPClient) {
        self.client = client
    }

    public func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue {
        try await client.callTool(name: name, arguments: arguments).extractedValue()
    }
}
