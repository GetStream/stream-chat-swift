//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// This protocol defines the methods that should be implemented by any class that wants to observe
/// app state changes.
protocol AppStateObserverDelegate: AnyObject {
    /// Will be triggered when the app moves to the background
    func applicationDidMoveToBackground()

    /// Will be triggered when the app moves to the foreground
    func applicationDidMoveToForeground()
}

/// This protocol describes an object that observes the state of an App and provides related information
/// to its observers.
protocol AppStateObserving {
    /// Adds the provided subscriber to the list of observers that will be informed once the state of the app
    /// changes.
    /// - Note: The list holds a weak reference to the subscriber
    func subscribe(_ subscriber: AppStateObserverDelegate)

    /// Removes the provided subscriber from the list of observers.
    func unsubscribe(_ subscriber: AppStateObserverDelegate)
}

/// A class responsible for observing changes to the app state.
final class StreamAppStateObserver: AppStateObserving {
    /// The NotificationCenter used for observing app state changes.
    let notificationCenter: NotificationCenter

    /// The observation tokens that are used to retain the notification subscription on the NotificationCenter
    private var didMoveToBackgroundObservationToken: Any?
    private var didMoveToForegroundObservationToken: Any?

    /// A multicastDelegate instance that is being used as subscribers handler. Manages the following operations:
    /// - Subscribe
    /// - Unsubscirbe
    /// - Inform all subscribers when a change occurs
    private var delegate: MulticastDelegate<AppStateObserverDelegate>

    // MARK: - Lifecycle

    /// Initializes an instance of StreamAppStateObserver with the provided notification center. If no
    /// notification center is provided, the default NotificationCenter will be used.
    init(
        notificationCenter: NotificationCenter = .default
    ) {
        self.notificationCenter = notificationCenter
        delegate = .init()

        setUp()
    }

    // MARK: - AppStateObserving

    /// Adds a subscriber to receive app state updates.
    func subscribe(_ subscriber: AppStateObserverDelegate) {
        delegate.add(additionalDelegate: subscriber)
    }

    /// Removes a subscriber from receiving app state updates.
    func unsubscribe(_ subscriber: AppStateObserverDelegate) {
        delegate.remove(additionalDelegate: subscriber)
    }

    // MARK: - Private API

    /// Sets up the observers for app moving to background and foreground notifications.
    private func setUp() {
        #if canImport(UIKit)
        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDidMoveToBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleAppDidMoveToForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        #endif
    }

    /// Handles the app moving to background notification by invoking the delegate method.
    @objc private func handleAppDidMoveToBackground() {
        delegate.invoke { $0.applicationDidMoveToBackground() }
    }

    /// Handles the app moving to foreground notification by invoking the delegate method.
    @objc private func handleAppDidMoveToForeground() {
        delegate.invoke { $0.applicationDidMoveToForeground() }
    }
}
