//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `BackgroundTaskScheduler`.
final class BackgroundTaskScheduler_Mock: BackgroundTaskScheduler, @unchecked Sendable {
    @Atomic var isAppActive_called: Bool = false
    @Atomic var isAppActive_returns: Bool = true
    var isAppActive: Bool {
        isAppActive_called = true
        return isAppActive_returns
    }

    @Atomic var beginBackgroundTask_called: Bool = false
    @Atomic var beginBackgroundTask_expirationHandler: (@MainActor () -> Void)?
    @Atomic var beginBackgroundTask_returns: Bool = true
    func beginTask(expirationHandler: (@MainActor () -> Void)?) -> Bool {
        beginBackgroundTask_called = true
        beginBackgroundTask_expirationHandler = expirationHandler
        return beginBackgroundTask_returns
    }

    @Atomic var endBackgroundTask_called: Bool = false
    func endTask() {
        endBackgroundTask_called = true
    }

    @Atomic var startListeningForAppStateUpdates_called: Bool = false
    @Atomic var startListeningForAppStateUpdates_onBackground: (() -> Void)?
    @Atomic var startListeningForAppStateUpdates_onForeground: (() -> Void)?
    func startListeningForAppStateUpdates(
        onEnteringBackground: @escaping () -> Void,
        onEnteringForeground: @escaping () -> Void
    ) {
        startListeningForAppStateUpdates_called = true
        startListeningForAppStateUpdates_onBackground = onEnteringBackground
        startListeningForAppStateUpdates_onForeground = onEnteringForeground
    }

    @Atomic var stopListeningForAppStateUpdates_called: Bool = false
    func stopListeningForAppStateUpdates() {
        stopListeningForAppStateUpdates_called = true
    }
}

extension BackgroundTaskScheduler_Mock {
    func simulateAppGoingToBackground() {
        isAppActive_returns = false
        startListeningForAppStateUpdates_onBackground?()
    }

    func simulateAppGoingToForeground() {
        isAppActive_returns = true
        startListeningForAppStateUpdates_onForeground?()
    }
}
