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

/// What a device reports for a call.
public struct AIClientToolResult: Equatable, Sendable {
    /// The result for the model, as a JSON object.
    public var output: Data?
    /// A short outcome every channel member sees on the step, such as "Shared approximate
    /// location". Keep the data itself out of it.
    public var summary: String?
    /// Why the device could not run the call, such as "Location not shared". Shown on the
    /// step and told to the model.
    public var failure: String?

    public init(output: Data? = nil, summary: String? = nil, failure: String? = nil) {
        self.output = output
        self.summary = summary
        self.failure = failure
    }

    /// A completed call, with its result for the model.
    public static func completed(_ output: some Encodable, summary: String? = nil) -> AIClientToolResult {
        guard let data = try? JSONEncoder().encode(output) else {
            return .failed("The result couldn't be read")
        }
        return AIClientToolResult(output: data, summary: summary)
    }

    /// A call the device could not run.
    public static func failed(_ reason: String) -> AIClientToolResult {
        AIClientToolResult(failure: reason)
    }
}

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
            Task { @MainActor [weak self] in
                let result: AIClientToolResult
                if let done {
                    result = done
                } else {
                    result = await tool.run(call)
                }
                await self?.deliver(result, for: call, send: send)
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

/// A stable identifier for this install, for addressing client tool calls to it. Put it in
/// the custom data of the person's message (`client_id`) so the agent can copy it onto the
/// calls it makes while answering.
public enum AIClientIdentity {
    private static let key = "io.getstream.ai.client-id"

    /// This install's identifier, created on first use.
    public static var installID: String {
        if let saved = UserDefaults.standard.string(forKey: key) { return saved }
        let created = "ios-" + UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }
}
