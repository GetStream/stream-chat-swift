//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// How the person signs in on this device when a tool call waits for their account at a
/// provider, and how their "not now" reaches your backend, which holds the call until one or
/// the other.
///
/// The sign-in opens in a web authentication session, which the sign-in page hands back to
/// `callbackScheme` once the provider has answered. Your backend then updates the call's step,
/// and the call goes on.
public struct AIToolAuthorizer: Sendable {
    /// Your app's own URL scheme, such as `com.example.app`. It is the scheme of the return URL
    /// your sessions give their sign-ins, which the sign-in page goes back to, with
    /// `status=connected` in its query once the account is connected.
    public var callbackScheme: String
    /// Tells your backend the person won't sign in now. Your backend ends the call, which never
    /// runs. A thrown error lets the person answer again.
    public var decline: @MainActor @Sendable (_ call: AIToolCallPart) async throws -> Void

    public init(
        callbackScheme: String,
        decline: @escaping @MainActor @Sendable (_ call: AIToolCallPart) async throws -> Void
    ) {
        self.callbackScheme = callbackScheme
        self.decline = decline
    }
}
