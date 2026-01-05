//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserDefaults {
    static let shared = UserDefaults(suiteName: applicationGroupIdentifier)!

    var currentUserId: String? {
        get { string(forKey: #function) }
        set { set(newValue, forKey: #function) }
    }

    var currentUser: UserCredentials? {
        currentUserId.flatMap { UserCredentials.builtInUsersByID(id: $0) }
    }
}
