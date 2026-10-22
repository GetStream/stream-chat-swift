//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// Asks for a tool call's sign-in, saying which provider it needs and what signing in means,
/// with buttons to connect or to say not now.
public struct AIToolAuthorizationCard: View {
    var authorization: AIToolAuthorization
    var state: AIToolAuthorizationState
    var connect: @MainActor @Sendable () -> Void
    var decline: @MainActor @Sendable () -> Void

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    public init(
        authorization: AIToolAuthorization,
        state: AIToolAuthorizationState = AIToolAuthorizationState(),
        connect: @escaping @MainActor @Sendable () -> Void,
        decline: @escaping @MainActor @Sendable () -> Void
    ) {
        self.authorization = authorization
        self.state = state
        self.connect = connect
        self.decline = decline
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: layout.spacingSm) {
            VStack(alignment: .leading, spacing: layout.spacingXxs) {
                Text(authorization.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(colors.toolApprovalTitle))
                if let message = authorization.message {
                    Text(message)
                        .font(fonts.toolApprovalMessage)
                        .foregroundStyle(Color(colors.toolApprovalMessage))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: layout.spacingXs) {
                Button(state.isConnecting ? L10n.ToolAuthorization.connecting : L10n.ToolAuthorization.connect) { connect() }
                    .buttonStyle(.borderedProminent)
                    .disabled(state.isBusy)
                // Left enabled while the sign-in is open, so a sign-in that never comes back
                // leaves the person a way out.
                Button(L10n.ToolAuthorization.decline) { decline() }
                    .buttonStyle(.bordered)
                    .disabled(state.isDeclining)
                if state.isBusy {
                    ProgressView().controlSize(.small)
                }
            }
            .controlSize(.small)
            .tint(Color(colors.toolApprovalAccent))
            if let failure {
                Text(failure)
                    .font(fonts.toolApprovalFailure)
                    .foregroundStyle(Color(colors.toolApprovalFailure))
            }
        }
        .font(fonts.messagePart)
        .padding(layout.spacingSm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(colors.toolApprovalBackground), in: RoundedRectangle(cornerRadius: layout.radiusLg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: layout.radiusLg, style: .continuous).strokeBorder(Color(colors.toolApprovalBorder)))
        .accessibilityElement(children: .contain)
    }

    /// What went wrong, such as the sign-in page not opening or the "not now" not reaching your
    /// backend.
    private var failure: String? {
        if state.connectFailed { return L10n.ToolAuthorization.notOpened }
        if state.declineFailed { return L10n.ToolApproval.notSent }
        return nil
    }
}
