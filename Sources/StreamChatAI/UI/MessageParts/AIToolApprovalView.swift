//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

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
    init(call: AIToolCallPart, approver: AIToolApprover, font: Font? = nil) {
        self.init(call: call, approver: approver) { approval, state, decide in
            AIToolApprovalCard(approval: approval, state: state, font: font, decide: decide)
        }
    }
}
