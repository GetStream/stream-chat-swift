//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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
