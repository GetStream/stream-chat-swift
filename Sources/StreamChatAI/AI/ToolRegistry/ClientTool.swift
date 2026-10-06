//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol representing a client-side tool that the AI agent can invoke.
/// Conforming types define how a tool is described, when it should be displayed, and how it responds to invocations.
public protocol ClientTool: AnyObject {
    /// The static definition of the tool, including its name, description and input schema,
    /// as communicated to the agent.
    var toolDefinition: ClientToolDefinition { get }

    /// Additional usage instructions or human-readable guidance that may be shown to users
    /// or the agent. This supplements the tool definition with contextual tips on
    /// how or when the tool should be used.
    var instructions: String { get }

    /// A Boolean value indicating whether the runtime should show a UI indicator when the tool
    /// relies on external data sources. When `true`, the client may visually signal that calls
    /// to this tool interact with systems outside the local model context.
    var showExternalSourcesIndicator: Bool { get }

    /// Handles an invocation of the tool from the agent. Implementations should inspect
    /// the incoming invocation payload, perform the necessary work, and return one or more
    /// `ClientToolAction` values describing the results or follow-up actions.
    ///
    /// - Parameter invocation: The invocation request containing arguments and metadata provided by the runtime.
    /// - Returns: A list of actions describing the tool’s response to the invocation.
    func handleInvocation(_ invocation: ClientToolInvocation) -> [ClientToolAction]
}
