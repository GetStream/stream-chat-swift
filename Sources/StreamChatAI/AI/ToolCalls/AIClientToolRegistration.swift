//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// How a client tool is described to the agent, for your backend to register it.
public struct AIClientToolRegistration: Encodable, Equatable, Sendable {
    /// The unique name of the tool. This is how the agent identifies it.
    public let name: String
    /// What the tool does: its description, or its instructions when it has none.
    public let description: String
    /// Guidance for the agent on when and how to use the tool.
    public let instructions: String?
    /// The JSON schema of the tool's arguments.
    public let parameters: RawJSON?
    /// Whether the app shows that the tool reaches outside the conversation while it runs.
    public let showExternalSourcesIndicator: Bool?

    @MainActor
    init(tool: any AIClientTool) {
        name = tool.definition.name
        description = tool.definition.description ?? tool.instructions ?? ""
        instructions = tool.instructions
        parameters = tool.definition.inputSchema
        showExternalSourcesIndicator = tool.showExternalSourcesIndicator
    }
}
