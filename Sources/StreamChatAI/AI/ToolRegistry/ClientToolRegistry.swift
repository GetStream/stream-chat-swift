//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A registry responsible for storing and managing all client tools available
/// to the AI agent. This class handles registration, lookup, and routing of
/// invocation requests to the appropriate tool instance.
public final class ClientToolRegistry {
    /// Internal storage mapping tool names to their corresponding `ClientTool` instances.
    private var toolsByName: [String: any ClientTool] = [:]

    /// Creates a new, empty tool registry.
    public init() {}

    /// Registers a client tool in the registry, making it discoverable by name.
    ///
    /// - Parameter tool: The tool to register. The registry uses the name defined in
    ///   `tool.toolDefinition.name` as the lookup key.
    public func register(tool: any ClientTool) {
        toolsByName[tool.toolDefinition.name] = tool
    }

    /// Produces the set of registration payloads for all registered tools. These
    /// payloads tell the agent the name, description, input schema, and behavior
    /// of each tool.
    ///
    /// - Returns: An array of `ToolRegistrationPayload` describing each registered tool.
    public func registrationPayloads() -> [ToolRegistrationPayload] {
        toolsByName.values.map { tool in
            ToolRegistrationPayload(
                name: tool.toolDefinition.name,
                description: tool.toolDefinition.description ?? tool.instructions,
                instructions: tool.instructions,
                parameters: tool.toolDefinition.inputSchema,
                showExternalSourcesIndicator: tool.showExternalSourcesIndicator
            )
        }
    }

    /// Routes an invocation request to the appropriate tool based on its name.
    /// If the referenced tool does not exist, an empty action array is returned.
    ///
    /// - Parameter invocation: The `ClientToolInvocation` containing the tool name
    ///   and invocation arguments.
    /// - Returns: A list of actions produced by the tool, or an empty array if the
    ///   requested tool is not registered.
    public func handleInvocation(_ invocation: ClientToolInvocation) -> [ClientToolAction] {
        guard let tool = toolsByName[invocation.tool.name] else { return [] }
        return tool.handleInvocation(invocation)
    }
}
