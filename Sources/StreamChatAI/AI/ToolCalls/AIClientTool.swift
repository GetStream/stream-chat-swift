//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A tool this device runs when an AI agent asks for it.
///
/// The agent writes the call on its reply as an `ai_tool_call` step with `executor: client`
/// and `status: awaiting_client`, addressed to one person and one install. An
/// `AIClientToolRunner` on that install runs it and sends the result back.
@MainActor
public protocol AIClientTool: AnyObject {
    /// The tool's name, as the agent declared it.
    var name: String { get }
    /// Runs one call. A call whose tool asks the person first reaches the device only once
    /// they allowed it, through `AIToolApprovalView`.
    func run(_ call: AIToolCallPart) async -> AIClientToolResult
}
