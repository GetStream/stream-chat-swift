//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The name, description and input schema of a client tool.
///
/// It reads and writes the same JSON as a Model Context Protocol tool (`name`, `description`
/// and `inputSchema`), so a tool defined with the MCP SDK converts without this SDK
/// depending on it:
///
/// ```swift
/// let definition = try ClientToolDefinition(encoding: mcpTool)
/// ```
public struct ClientToolDefinition: Codable, Hashable, Sendable {
    /// The unique name of the tool.
    public var name: String
    /// A description of what the tool does, for the agent.
    public var description: String?
    /// The JSON schema of the tool's arguments.
    public var inputSchema: AIJSONValue?

    public init(name: String, description: String? = nil, inputSchema: AIJSONValue? = nil) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }

    /// Creates a definition from another tool type that encodes `name`, `description`
    /// and `inputSchema`, such as the MCP SDK's `Tool`.
    public init(encoding tool: some Encodable) throws {
        self = try JSONDecoder().decode(Self.self, from: JSONEncoder().encode(tool))
    }
}
