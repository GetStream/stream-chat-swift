//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// The name, description and argument schema of a client tool.
///
/// It reads and writes the same JSON as a Model Context Protocol tool (`name`, `description`,
/// `inputSchema` and the `readOnlyHint` of its `annotations`), so a tool defined with the MCP SDK
/// converts without this SDK depending on it:
///
/// ```swift
/// let definition = try AIClientToolDefinition(encoding: mcpTool)
/// ```
@available(iOS 15.0, macOS 12.0, *)
public struct AIClientToolDefinition: Codable, Hashable, Sendable {
    /// The unique name of the tool.
    public var name: String
    /// A description of what the tool does, for the agent.
    public var description: String?
    /// The JSON schema of the tool's arguments.
    public var inputSchema: RawJSON?
    /// Hints about how the tool behaves, such as whether it only reads.
    public var annotations: Annotations?

    public init(
        name: String,
        description: String? = nil,
        inputSchema: RawJSON? = nil,
        annotations: Annotations? = nil
    ) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.annotations = annotations
    }

    /// Whether the tool only reads and changes nothing, as its `readOnlyHint` says. A reply's UI
    /// runs only such a tool by itself, such as to load data while it shows. Any other runs only
    /// when the person asks for it.
    public var isReadOnly: Bool {
        annotations?.readOnlyHint == true
    }

    /// Hints about how a tool behaves, as a Model Context Protocol tool's `annotations`.
    public struct Annotations: Codable, Hashable, Sendable {
        /// Whether the tool only reads, and changes nothing.
        public var readOnlyHint: Bool?

        public init(readOnlyHint: Bool? = nil) {
            self.readOnlyHint = readOnlyHint
        }
    }

    /// Creates a definition from another tool type that encodes `name`, `description`,
    /// `inputSchema` and `annotations`, such as the MCP SDK's `Tool`.
    public init(encoding tool: some Encodable) throws {
        self = try JSONDecoder().decode(Self.self, from: JSONEncoder().encode(tool))
    }
}
