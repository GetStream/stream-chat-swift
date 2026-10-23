//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Asks the person a tool call waits for to sign in at the provider it needs, with the sign-in
/// its `ai_tool_call` step carries (status `awaiting_authorization`, with `authorization`).
/// Connect opens the sign-in page in a web authentication session. Once the provider has
/// answered, your backend updates the step and the call goes on. It shows only to that person,
/// only while the call waits, and only with an `AIToolAuthorizer`, so it can sit under every
/// tool call:
///
/// ```swift
/// AIToolCallView(part: call)
/// AIToolAuthorizationView(call: call, approver: approver)
/// ```
///
/// It asks with the view factory's
/// ``AIConversationViewFactory/makeToolAuthorizationView(options:)``, an
/// ``AIToolAuthorizationCard`` by default. To ask in your own design, return yours there.
public struct AIToolAuthorizationView<Factory: AIConversationViewFactory>: View {
    var viewFactory: Factory
    var call: AIToolCallPart
    var approver: AIToolApprover
    @State private var state = AIToolAuthorizationState()
    @State private var session = AIWebAuthentication()

    /// - Parameters:
    ///   - viewFactory: The view that asks for the sign-in.
    ///   - call: The tool call that may wait for a sign-in.
    ///   - approver: Who answers on this device, with the `AIToolAuthorizer` the sign-in needs.
    public init(
        viewFactory: Factory = DefaultAIConversationViewFactory.shared,
        call: AIToolCallPart,
        approver: AIToolApprover
    ) {
        self.viewFactory = viewFactory
        self.call = call
        self.approver = approver
    }

    public var body: some View {
        if let authorizer = approver.authorizer, let authorization = approver.signIn(for: call) {
            viewFactory.makeToolAuthorizationView(
                options: AIToolAuthorizationViewOptions(
                    call: call,
                    authorization: authorization,
                    state: state,
                    connect: { connect(authorization, authorizer) },
                    decline: { decline(authorizer) }
                )
            )
        }
    }

    private func connect(_ authorization: AIToolAuthorization, _ authorizer: AIToolAuthorizer) {
        guard !state.isBusy else { return }
        state = AIToolAuthorizationState(isConnecting: true)
        let session = session
        Task { @MainActor in
            do {
                let returned = try await session.authenticate(
                    using: authorization.launchURL, callbackURLScheme: authorizer.callbackScheme
                )
                // Your backend has the provider's answer before the page comes back, and its
                // change to the step hides this. Until then it says it is connecting, unless the
                // person closed the sheet or the provider did not connect them.
                if returned.map(Self.connected) != true {
                    state = AIToolAuthorizationState()
                }
            } catch {
                state = AIToolAuthorizationState(connectFailed: true)
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
                state = AIToolAuthorizationState(declineFailed: true)
            }
        }
    }

    /// Whether the page came back saying the account is connected, with `status=connected` in
    /// its query.
    static func connected(_ returned: URL) -> Bool {
        URLComponents(url: returned, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "status" })?.value == "connected"
    }
}

extension AIToolApprover {
    /// The sign-in this person is asked for on `call` here. It is one the call waits for them
    /// to finish, of a kind this device opens, and only asked when they can sign in on it.
    func signIn(for call: AIToolCallPart) -> AIToolAuthorization? {
        guard authorizer != nil, call.isAwaitingAuthorization(userID: userID),
              let authorization = call.authorization, authorization.kind == .oauth else { return nil }
        return authorization
    }
}
