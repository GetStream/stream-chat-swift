//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The person answering tool calls' questions on this device, and how their answer reaches
/// your backend, which holds each call until it gets one.
public struct AIToolApprover {
    /// The person signed in, matched against a call's `target_user_id`.
    public var userID: String
    /// This install, matched against a client tool call's `target_client_id`. Use
    /// `AIClientIdentity.installID`.
    public var clientID: String
    /// Sends the answer. Your backend checks it is this person's (and this install's, for a
    /// client tool), then updates the call's step; until then the question stays, with its
    /// buttons disabled. A thrown error lets the person answer again.
    public var decide: @MainActor @Sendable (_ call: AIToolCallPart, _ allowed: Bool) async throws -> Void

    public init(
        userID: String,
        clientID: String,
        decide: @escaping @MainActor @Sendable (_ call: AIToolCallPart, _ allowed: Bool) async throws -> Void
    ) {
        self.userID = userID
        self.clientID = clientID
        self.decide = decide
    }
}

/// Where the person's answer to a question is.
public struct AIToolApprovalState: Equatable, Sendable {
    /// The answer is on its way, or arrived and the call's step hasn't changed yet.
    public var isSending = false
    /// The answer couldn't be sent, and the person can answer again.
    public var failed = false

    public init(isSending: Bool = false, failed: Bool = false) {
        self.isSending = isSending
        self.failed = failed
    }
}

/// Asks the person a tool call waits for whether it may run: the question its `ai_tool_call`
/// step carries (status `awaiting_approval`, with `approval`). It shows only to that person,
/// on the device the call names, and only while the call waits, so it can sit under every
/// tool call:
///
/// ```swift
/// AIToolCallView(part: call)
/// AIToolApprovalView(call: call, approver: approver)
/// ```
///
/// To ask in your own design, pass the content. It gets the question, where the answer is,
/// and a closure that answers:
///
/// ```swift
/// AIToolApprovalView(call: call, approver: approver) { approval, state, decide in
///     MyApprovalCard(title: approval.title, busy: state.isSending, onAllow: { decide(true) }, onDecline: { decide(false) })
/// }
/// ```
public struct AIToolApprovalView<Content: View>: View {
    var call: AIToolCallPart
    var approver: AIToolApprover
    var content: (AIToolApproval, AIToolApprovalState, @escaping @MainActor @Sendable (Bool) -> Void) -> Content
    @State private var state = AIToolApprovalState()

    public init(
        call: AIToolCallPart,
        approver: AIToolApprover,
        @ViewBuilder content: @escaping (
            _ approval: AIToolApproval,
            _ state: AIToolApprovalState,
            _ decide: @escaping @MainActor @Sendable (_ allowed: Bool) -> Void
        ) -> Content
    ) {
        self.call = call
        self.approver = approver
        self.content = content
    }

    public var body: some View {
        if call.isAwaitingApproval(userID: approver.userID, clientID: approver.clientID), let approval = call.approval {
            content(approval, state) { allowed in answer(allowed) }
        }
    }

    private func answer(_ allowed: Bool) {
        guard !state.isSending else { return }
        state = AIToolApprovalState(isSending: true)
        let call = call
        let decide = approver.decide
        Task { @MainActor in
            do {
                try await decide(call, allowed)
            } catch {
                state = AIToolApprovalState(failed: true)
            }
        }
    }
}

public extension AIToolApprovalView where Content == AIToolApprovalCard {
    /// Asks with `AIToolApprovalCard`.
    init(call: AIToolCallPart, approver: AIToolApprover, font: Font = .subheadline, colors: Colors = Colors()) {
        self.init(call: call, approver: approver) { approval, state, decide in
            AIToolApprovalCard(approval: approval, state: state, font: font, colors: colors, decide: decide)
        }
    }
}

/// A tool call's question: what it asks, the agent's reason and what allowing it shares, and
/// buttons to allow or decline it.
public struct AIToolApprovalCard: View {
    var approval: AIToolApproval
    var state: AIToolApprovalState
    var font: Font
    var colors: Colors.ToolApprovals
    var decide: @MainActor @Sendable (Bool) -> Void

    public init(
        approval: AIToolApproval,
        state: AIToolApprovalState = AIToolApprovalState(),
        font: Font = .subheadline,
        colors: Colors = Colors(),
        decide: @escaping @MainActor @Sendable (_ allowed: Bool) -> Void
    ) {
        self.approval = approval
        self.state = state
        self.font = font
        self.colors = colors.toolApprovals
        self.decide = decide
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(approval.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(colors.title)
                ForEach(Self.lines(of: approval), id: \.self) { line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(colors.message)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 8) {
                Button(approval.allowTitle) { decide(true) }
                    .buttonStyle(.borderedProminent)
                Button(approval.declineTitle) { decide(false) }
                    .buttonStyle(.bordered)
                if state.isSending {
                    ProgressView().controlSize(.small)
                }
            }
            .controlSize(.small)
            .tint(colors.accent)
            .disabled(state.isSending)
            if state.failed {
                Text(L10n.ToolApproval.notSent)
                    .font(.caption)
                    .foregroundStyle(colors.failure)
            }
        }
        .font(font)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(colors.border))
        .accessibilityElement(children: .contain)
    }

    /// The agent's reason, as a sentence, then what allowing it shares.
    static func lines(of approval: AIToolApproval) -> [String] {
        var lines: [String] = []
        if let reason = approval.reason?.trimmingCharacters(in: .whitespacesAndNewlines), let first = reason.first {
            let sentence = first.uppercased() + reason.dropFirst()
            lines.append(sentence.last.map { ".!?…".contains($0) } == true ? sentence : sentence + ".")
        }
        if let message = approval.message {
            lines.append(message)
        }
        return lines
    }
}
