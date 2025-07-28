//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Object responsible for platform specific handling of background tasks
protocol BackgroundTaskScheduler {
    /// It's your responsibility to finish previously running task.
    ///
    /// Returns: `false` if system forbid background task, `true` otherwise
    func beginTask(expirationHandler: (() -> Void)?) -> Bool
    func endTask()
    func startListeningForAppStateUpdates(
        onEnteringBackground: @escaping () -> Void,
        onEnteringForeground: @escaping () -> Void
    )
    func stopListeningForAppStateUpdates()

    var isAppActive: Bool { get }
}

#if os(iOS)
import UIKit

class IOSBackgroundTaskScheduler: BackgroundTaskScheduler {
    private lazy var app: UIApplication? = {
        // We can't use `UIApplication.shared` directly because there's no way to convince the compiler
        // this code is accessible only for non-extension executables.
        UIApplication.value(forKeyPath: "sharedApplication") as? UIApplication
    }()

    /// The identifier of the currently running background task. `nil` if no background task is running.
    private var activeBackgroundTask: UIBackgroundTaskIdentifier?
    private let queue = DispatchQueue(label: "io.getstream.IOSBackgroundTaskScheduler", target: .global())

    var isAppActive: Bool {
        if Thread.isMainThread {
            return app?.applicationState == .active
        }

        var isActive = false
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            isActive = self.app?.applicationState == .active
            group.leave()
        }
        group.wait()
        return isActive
    }

    func beginTask(expirationHandler: (() -> Void)?) -> Bool {
        // Only a single task is allowed at the same time
        endTask()
        
        guard let app else { return false }
        let identifier = app.beginBackgroundTask { [weak self] in
            self?.endTask()
            expirationHandler?()
        }
        queue.sync {
            self.activeBackgroundTask = identifier
        }
        return identifier != .invalid
    }

    func endTask() {
        guard let app else { return }
        queue.sync {
            if let identifier = self.activeBackgroundTask {
                self.activeBackgroundTask = nil
                app.endBackgroundTask(identifier)
            }
        }
    }

    private var onEnteringBackground: () -> Void = {}
    private var onEnteringForeground: () -> Void = {}

    func startListeningForAppStateUpdates(
        onEnteringBackground: @escaping () -> Void,
        onEnteringForeground: @escaping () -> Void
    ) {
        queue.sync {
            self.onEnteringForeground = onEnteringForeground
            self.onEnteringBackground = onEnteringBackground
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    func stopListeningForAppStateUpdates() {
        queue.sync {
            self.onEnteringForeground = {}
            self.onEnteringBackground = {}
        }

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func handleAppDidEnterBackground() {
        let callback = queue.sync { onEnteringBackground }
        callback()
    }

    @objc private func handleAppDidBecomeActive() {
        let callback = queue.sync { onEnteringForeground }
        callback()
    }

    deinit {
        endTask()
    }
}

#endif
