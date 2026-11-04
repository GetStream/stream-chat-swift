//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatAI

// Runs the tools of `Query()` and `Mutation()` with the host's tools. It keeps the host weakly,
// as the engine does: the host keeps the engine, which keeps this.
@available(iOS 17.0, macOS 14.0, *)
struct HostToolProvider: OpenUIToolProvider {
    weak var host: (any AIUIHosting)?

    func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue {
        try await callTool(name, arguments: arguments, userInitiated: false)
    }

    // A `Query` runs only a read-only tool; a `Mutation`, from a tap, runs any of the host's.
    func callTool(_ name: String, arguments: OpenUIObject, userInitiated: Bool) async throws -> OpenUIValue {
        guard let host else { throw ConversationClosedError(toolName: name) }
        return try await host.runTool(name, arguments: arguments.rawJSON, userInitiated: userInitiated).openUIValue
    }
}

// A tool a reply's UI ran after its conversation was closed.
struct ConversationClosedError: LocalizedError {
    let toolName: String

    var errorDescription: String? { "\(toolName) can't run: the conversation was closed." }
}
