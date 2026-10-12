//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// The name, description and argument schema of a client tool.
///
/// It reads and writes the same JSON as a Model Context Protocol tool (`name`, `description`
/// and `inputSchema`), so a tool defined with the MCP SDK converts without this SDK
/// depending on it:
///
/// ```swift
/// let definition = try AIClientToolDefinition(encoding: mcpTool)
/// ```
public struct AIClientToolDefinition: Codable, Hashable, Sendable {
    /// The unique name of the tool.
    public var name: String
    /// A description of what the tool does, for the agent.
    public var description: String?
    /// The JSON schema of the tool's arguments.
    public var inputSchema: RawJSON?

    public init(name: String, description: String? = nil, inputSchema: RawJSON? = nil) {
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
