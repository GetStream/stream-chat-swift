//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a client-side invocation of a tool, including the tool's metadata
/// and any arguments provided by the agent.
public final class ClientToolInvocation {
    /// A descriptor containing metadata about a tool being invoked.
    public final class ToolDescriptor {
        /// The unique name of the tool being invoked.
        public let name: String

        /// A human-readable description of the tool, if provided.
        public let description: String?

        /// Additional instructions or usage guidance associated with the tool.
        public let instructions: String?

        /// The raw-encoded input parameter schema for the tool, typically encoded as JSON.
        public let parameters: Data?

        /// Creates a new tool descriptor.
        ///
        /// - Parameters:
        ///   - name: The unique identifier of the tool.
        ///   - description: A user-facing description of the tool.
        ///   - instructions: Supplementary guidance about how to use the tool.
        ///   - parameters: Raw input schema data, if available.
        public init(
            name: String,
            description: String?,
            instructions: String?,
            parameters: Data?
        ) {
            self.name = name
            self.description = description
            self.instructions = instructions
            self.parameters = parameters
        }
    }

    /// Metadata describing the tool being invoked.
    public let tool: ToolDescriptor

    /// The raw arguments associated with the invocation, typically encoded as JSON.
    public let args: Data?

    /// An optional message identifier associated with the context of the invocation.
    /// This may be used to correlate tool responses to originating messages.
    public let messageId: String?

    /// An optional channel identifier indicating the source or conversational
    /// context in which the invocation occurred.
    public let channelId: AnyHashable?

    /// Creates a new tool invocation containing metadata and raw arguments.
    ///
    /// - Parameters:
    ///   - tool: The descriptor of the tool being invoked.
    ///   - args: Raw encoded arguments supplied for the invocation.
    ///   - messageId: The ID of the associated message, if any.
    ///   - channelId: A channel or thread identifier for contextual routing.
    public init(
        tool: ToolDescriptor,
        args: Data?,
        messageId: String?,
        channelId: AnyHashable?
    ) {
        self.tool = tool
        self.args = args
        self.messageId = messageId
        self.channelId = channelId
    }
}
