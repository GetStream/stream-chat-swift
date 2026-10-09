//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Runs the client tool calls addressed to this device, each once.
///
/// Give it each AI reply's steps as they update. It runs a call when the call awaits this
/// person and this install, the runner has a tool of that name and the call has not run
/// here before, then hands the result to `send`. A result that could not be sent is sent
/// again on a later update, without running the tool again.
///
/// ```swift
/// let runner = AIClientToolRunner(userID: me.id, clientID: AIClientIdentity.installID, tools: [LocationTool()])
/// runner.run(parts) { call, result in try await backend.send(result, for: call, in: message) }
/// ```
@MainActor
public final class AIClientToolRunner {
    public let userID: String
    public let clientID: String
    private var tools: [String: any AIClientTool]
    private var calls: [String: Call] = [:]

    /// How many times a result is offered to `send` before the runner gives up on it.
    public var maxAttempts = 3

    private final class Call {
        var result: AIClientToolResult?
        var attempts = 0
        var sending = false
        var sent = false
    }

    public init(userID: String, clientID: String, tools: [any AIClientTool]) {
        self.userID = userID
        self.clientID = clientID
        self.tools = Dictionary(tools.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The names of the tools this device can run.
    public var toolNames: [String] { tools.keys.sorted() }

    /// How this device's tools are described to the agent, sorted by name. Send them to your
    /// backend so the agent knows it can call them.
    public var registrations: [AIClientToolRegistration] {
        toolNames.compactMap { tools[$0] }.map(AIClientToolRegistration.init(tool:))
    }

    /// Runs the calls among `parts` that await this device, and sends their results.
    public func run(
        _ parts: [AIMessagePart],
        send: @escaping @MainActor (AIToolCallPart, AIClientToolResult) async throws -> Void
    ) {
        for call in parts.compactMap(\.toolCall) where call.isAwaiting(userID: userID, clientID: clientID) {
            guard let tool = tools[call.name] else { continue }
            let state = calls[call.id] ?? Call()
            guard !state.sending, !state.sent, state.attempts < maxAttempts else { continue }
            state.sending = true
            calls[call.id] = state
            let done = state.result
            // Holds the runner until the result is delivered: a runner released while its tool
            // runs would otherwise drop the result, and a new runner would run the tool again.
            Task { @MainActor in
                let result: AIClientToolResult
                if let done {
                    result = done
                } else {
                    result = await tool.run(call)
                }
                await self.deliver(result, for: call, send: send)
            }
        }
    }

    private func deliver(
        _ result: AIClientToolResult,
        for call: AIToolCallPart,
        send: @MainActor (AIToolCallPart, AIClientToolResult) async throws -> Void
    ) async {
        calls[call.id]?.result = result
        calls[call.id]?.attempts += 1
        do {
            try await send(call, result)
            calls[call.id]?.sent = true
        } catch {
            // Offered again on the next update that still shows the call waiting.
        }
        calls[call.id]?.sending = false
    }
}
