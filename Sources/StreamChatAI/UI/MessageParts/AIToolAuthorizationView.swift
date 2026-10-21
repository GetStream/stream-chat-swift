//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AuthenticationServices
import SwiftUI

/// Asks the person a tool call waits for to sign in at the provider it needs: the sign-in its
/// `ai_tool_call` step carries (status `awaiting_authorization`, with `authorization`). Connect
/// opens the sign-in page in a web authentication session; once the provider has answered,
/// your backend updates the step and the call goes on. It shows only to that person, only
/// while the call waits, and only with an `AIToolAuthorizer`, so it can sit under every tool
/// call:
///
/// ```swift
/// AIToolCallView(part: call)
/// AIToolAuthorizationView(call: call, approver: approver)
/// ```
///
/// To ask in your own design, pass the content. It gets the sign-in, where it is, and closures
/// that connect and decline:
///
/// ```swift
/// AIToolAuthorizationView(call: call, approver: approver) { authorization, state, connect, decline in
///     MySignInCard(title: authorization.title, busy: state.isBusy, onConnect: connect, onDecline: decline)
/// }
/// ```
@available(iOS 16.4, macOS 13.3, *)
public struct AIToolAuthorizationView<Content: View>: View {
    var call: AIToolCallPart
    var approver: AIToolApprover
    var content: (
        AIToolAuthorization,
        AIToolAuthorizationState,
        @escaping @MainActor @Sendable () -> Void,
        @escaping @MainActor @Sendable () -> Void
    ) -> Content
    @State private var state = AIToolAuthorizationState()
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    public init(
        call: AIToolCallPart,
        approver: AIToolApprover,
        @ViewBuilder content: @escaping (
            _ authorization: AIToolAuthorization,
            _ state: AIToolAuthorizationState,
            _ connect: @escaping @MainActor @Sendable () -> Void,
            _ decline: @escaping @MainActor @Sendable () -> Void
        ) -> Content
    ) {
        self.call = call
        self.approver = approver
        self.content = content
    }

    public var body: some View {
        if let authorizer = approver.authorizer, call.isAwaitingAuthorization(userID: approver.userID),
           let authorization = call.authorization, authorization.kind == .oauth {
            content(authorization, state, { connect(authorization, authorizer) }, { decline(authorizer) })
        }
    }

    private func connect(_ authorization: AIToolAuthorization, _ authorizer: AIToolAuthorizer) {
        guard !state.isBusy else { return }
        state = AIToolAuthorizationState(isConnecting: true)
        let session = webAuthenticationSession
        Task { @MainActor in
            do {
                // The step changes once your backend has the provider's answer, which hides this.
                _ = try await session.authenticate(
                    using: authorization.launchURL, callbackURLScheme: authorizer.callbackScheme
                )
            } catch ASWebAuthenticationSessionError.canceledLogin {
                state = AIToolAuthorizationState()
            } catch {
                state = AIToolAuthorizationState(failed: true)
            }
        }
    }

    private func decline(_ authorizer: AIToolAuthorizer) {
        guard !state.isDeclining else { return }
        state = AIToolAuthorizationState(isDeclining: true)
        let call = call
        let decline = authorizer.decline
        Task { @MainActor in
            do {
                try await decline(call)
            } catch {
                state = AIToolAuthorizationState(failed: true)
            }
        }
    }
}

@available(iOS 16.4, macOS 13.3, *)
public extension AIToolAuthorizationView where Content == AIToolAuthorizationCard {
    /// Asks with `AIToolAuthorizationCard`.
    init(call: AIToolCallPart, approver: AIToolApprover, font: Font? = nil) {
        self.init(call: call, approver: approver) { authorization, state, connect, decline in
            AIToolAuthorizationCard(authorization: authorization, state: state, font: font, connect: connect, decline: decline)
        }
    }
}
