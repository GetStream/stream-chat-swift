//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A tool this device runs when an AI agent asks for it.
///
/// Describe it to the agent with ``AIClientToolRunner/registrations``. The agent writes each
/// call on its reply as an `ai_tool_call` step with `executor: client` and
/// `status: awaiting_client`, addressed to one person and one install. An
/// `AIClientToolRunner` on that install runs it and sends the result back.
@MainActor
public protocol AIClientTool: AnyObject {
    /// The tool's name, description and argument schema, as the agent sees them.
    var definition: AIClientToolDefinition { get }
    /// Guidance for the agent on when and how to use the tool, sent with its definition.
    var instructions: String? { get }
    /// Whether the app shows that the tool reaches outside the conversation while it runs.
    var showExternalSourcesIndicator: Bool { get }
    /// Runs one call. A call whose tool asks the person first reaches the device only once
    /// they allowed it, through `AIToolApprovalView`.
    func run(_ call: AIToolCallPart) async -> AIClientToolResult
}

public extension AIClientTool {
    /// The tool's name, as the agent declared it.
    var name: String { definition.name }

    var instructions: String? { nil }

    var showExternalSourcesIndicator: Bool { false }
}
