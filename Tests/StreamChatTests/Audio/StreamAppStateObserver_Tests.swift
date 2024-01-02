//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestTools
import UIKit
import XCTest

final class StreamAppStateObserver_Tests: XCTestCase {
    private lazy var notificationCenter: StubNotificationCenter! = .init()
    private lazy var appStateObserver: StreamAppStateObserver! = .init(notificationCenter: notificationCenter)

    override func tearDown() {
        appStateObserver = nil
        notificationCenter = nil
        super.tearDown()
    }

    // MARK: - subscribe

    func test_subscribe_allSubscribersWillBeNotifiedWhenAppStateChanges() {
        let subscriberA = SpyAppStateObserverDelegate()
        let subscriberB = SpyAppStateObserverDelegate()

        appStateObserver.subscribe(subscriberA)
        appStateObserver.subscribe(subscriberB)

        simulateAppDidMoveToBackground()

        [subscriberA, subscriberB].forEach { subscriber in
            XCTAssertEqual(subscriber.recordedFunctions, [
                "applicationDidMoveToBackground()"
            ])
        }

        simulateAppDidMoveToForeground()

        [subscriberA, subscriberB].forEach { subscriber in
            XCTAssertEqual(subscriber.recordedFunctions, [
                "applicationDidMoveToBackground()",
                "applicationDidMoveToForeground()"

            ])
        }
    }

    // MARK: - unsubscribe

    func test_unsubscribe_onlyRemainigSubscribersWillBeNotifiedWhenAppStateChanges() {
        let subscriberA = SpyAppStateObserverDelegate()
        let subscriberB = SpyAppStateObserverDelegate()

        appStateObserver.subscribe(subscriberA)
        appStateObserver.subscribe(subscriberB)

        simulateAppDidMoveToBackground()

        [subscriberA, subscriberB].forEach { subscriber in
            XCTAssertEqual(subscriber.recordedFunctions, [
                "applicationDidMoveToBackground()"
            ])
        }

        appStateObserver.unsubscribe(subscriberA)

        simulateAppDidMoveToForeground()

        XCTAssertEqual(subscriberA.recordedFunctions, [
            "applicationDidMoveToBackground()"
        ])
        XCTAssertEqual(subscriberB.recordedFunctions, [
            "applicationDidMoveToBackground()",
            "applicationDidMoveToForeground()"

        ])
    }

    // MARK: - Private Helpers

    private func simulateAppDidMoveToBackground() {
        notificationCenter.observersMap[UIApplication.didEnterBackgroundNotification]?
            .forEach { $0.execute() }
    }

    private func simulateAppDidMoveToForeground() {
        notificationCenter.observersMap[UIApplication.didBecomeActiveNotification]?
            .forEach { $0.execute() }
    }
}

private final class StubNotificationCenter: NotificationCenter {
    struct ObserverRecord {
        var observer: AnyObject
        var selector: Selector

        func execute() { _ = observer.perform(selector, with: nil) }
    }

    private(set) var observersMap: [NSNotification.Name: [ObserverRecord]] = [:]

    override func addObserver(
        _ observer: Any,
        selector aSelector: Selector,
        name aName: NSNotification.Name?,
        object anObject: Any?
    ) {
        guard let aName = aName else { return }

        if observersMap[aName] == nil {
            observersMap[aName] = []
        }

        observersMap[aName]?.append(.init(
            observer: observer as AnyObject,
            selector: aSelector
        ))
    }
}

private final class SpyAppStateObserverDelegate: AppStateObserverDelegate, Spy {
    var recordedFunctions: [String] = []

    func applicationDidMoveToBackground() {
        record()
    }

    func applicationDidMoveToForeground() {
        record()
    }
}
