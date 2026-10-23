//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

/// Opens a page in a web authentication session and returns the URL the page hands back to its
/// callback scheme. It works from iOS 13, where SwiftUI's `webAuthenticationSession` needs 16.4.
@MainActor
final class AIWebAuthentication: NSObject {
    /// The session couldn't be opened.
    struct Failed: Error {}

    private var session: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<URL?, Error>?

    /// The URL the page handed back, or nil when the person closed the sheet.
    func authenticate(using url: URL, callbackURLScheme: String) async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { callback, error in
                let cancelled = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
                Task { @MainActor in self.finish(callback, cancelled: cancelled) }
            }
            session.presentationContextProvider = self
            self.session = session
            if !session.start() {
                finish(nil, cancelled: false)
            }
        }
    }

    // The session may answer after a start that failed, so it is answered once.
    private func finish(_ callback: URL?, cancelled: Bool) {
        guard let continuation else { return }
        self.continuation = nil
        session = nil
        if let callback {
            continuation.resume(returning: callback)
        } else if cancelled {
            continuation.resume(returning: nil)
        } else {
            continuation.resume(throwing: Failed())
        }
    }
}

extension AIWebAuthentication: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}
