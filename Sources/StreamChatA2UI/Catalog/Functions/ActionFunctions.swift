//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The side effecting functions of the A2UI basic catalog.
@available(iOS 15.0, macOS 12.0, *)
enum ActionFunctions {
    /// All action functions, in catalog order.
    static var all: [FunctionDefinition] {
        [openUrl]
    }

    /// URL schemes the renderer is willing to open on behalf of an agent.
    ///
    /// Agent-generated content is untrusted, so the basic catalog only opens
    /// web pages; anything else is rejected instead of being handed to the system.
    static let allowedUrlSchemes: Set<String> = ["http", "https"]

    /// Opens a URL with the platform handler, in response to a user action.
    static let openUrl = FunctionDefinition(
        name: "openUrl",
        description: "Opens the specified URL in a browser or handler (requires user activation). This function has no return value.",
        arguments: JsonSchema.object(
            properties: [
                "url": JsonSchema.oneOf(
                    [
                        JsonSchema.string(format: "uri"),
                        JsonSchema.commonType("DataBinding"),
                        JsonSchema.commonType("FunctionCall")
                    ],
                    description: "The URL to open."
                )
            ],
            required: ["url"],
            additionalProperties: false
        ),
        returnType: .void,
        requiresUserActivation: true
    ) { invocation in
        let raw = try invocation.requireString("url")
        guard let url = URL(string: raw), let scheme = url.scheme?.lowercased() else {
            throw A2UIFunctionError.invalidArgument(
                "url",
                function: "openUrl",
                reason: "'\(raw)' is not a valid URL."
            )
        }
        guard allowedUrlSchemes.contains(scheme) else {
            throw A2UIFunctionError.invalidArgument(
                "url",
                function: "openUrl",
                reason: "The '\(scheme)' scheme is not allowed."
            )
        }
        invocation.services.openUrl(url)
        return nil
    }
}
