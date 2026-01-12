//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Bundle {
    static var pushProviderName: String? {
        main.infoDictionary?["PushNotification-Configuration"] as? String
    }
}
