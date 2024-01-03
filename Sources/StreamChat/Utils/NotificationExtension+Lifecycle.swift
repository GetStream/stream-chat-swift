//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

class NotificationExtensionLifecycle {
    private lazy var userDefaults = appGroupIdentifier.flatMap(UserDefaults.init(suiteName:))
    private let isReceivingEventsKey = "stream.extension.is-receiving-events"
    private let appGroupIdentifier: String?

    init(appGroupIdentifier: String?) {
        self.appGroupIdentifier = appGroupIdentifier
    }

    var isAppReceivingWebSocketEvents: Bool {
        guard let userDefaults = userDefaults else {
            logMissingAppGroupIfNeeded()
            return false
        }
        return userDefaults.bool(forKey: isReceivingEventsKey)
    }

    func setAppState(isReceivingEvents: Bool) {
        userDefaults?.set(isReceivingEvents, forKey: isReceivingEventsKey)
    }

    private func logMissingAppGroupIfNeeded() {
        let isExtension = Bundle.main.bundleURL.pathExtension == "appex"
        guard isExtension else { return }
        log.debug("Unable to share data between the host app and the extension. App Groups is not set up, or has incorrect values")
    }
}
