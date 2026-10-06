//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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
