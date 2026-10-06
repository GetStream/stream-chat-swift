//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A payload describing a tool to the agent during registration.
/// This structure encapsulates the metadata, usage instructions, parameter schema,
/// and optional UI behaviors associated with the tool.
public final class ToolRegistrationPayload: Encodable {
    /// The unique name of the tool. This is how the agent identifies it.
    public let name: String

    /// A user-facing description summarizing the tool's purpose and behavior.
    public let description: String

    /// Optional instructional text offering additional guidance about how or
    /// when to use the tool.
    public let instructions: String?

    /// The tool's expected input parameter schema.
    /// This describes the shape of the arguments the tool accepts.
    public let parameters: AIJSONValue?

    /// Indicates whether the client UI should display an indicator when the tool
    /// interacts with external data sources.
    public let showExternalSourcesIndicator: Bool?

    init(name: String, description: String, instructions: String?, parameters: AIJSONValue?, showExternalSourcesIndicator: Bool?) {
        self.name = name
        self.description = description
        self.instructions = instructions
        self.parameters = parameters
        self.showExternalSourcesIndicator = showExternalSourcesIndicator
    }
}
