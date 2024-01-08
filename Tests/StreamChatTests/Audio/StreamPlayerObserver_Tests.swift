//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamChat
import XCTest

final class StreamPlayerObserver_Tests: XCTestCase {
    private lazy var notificationCenter: MockNotificationCenter! = .init()
    private lazy var player: MockAVPlayer! = .init()
    private lazy var subject: StreamPlayerObserver! = .init(
        notificationCenter: notificationCenter
    )

    override func tearDownWithError() throws {
        notificationCenter = nil
        player = nil
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - addTimeControlStatusObserver

    // We cannot test addTimeControlStatusObserver as it relies on KVO observers
    // which cannot be spied or mocked.

    // MARK: - addPeriodicTimeObserver

    func test_addPeriodicTimeObserver_addPeriodicTimeObserverWasCalledOnPlayerWithExpectedValues() {
        let interval = CMTimeMake(value: 100, timescale: 200)

        subject.addPeriodicTimeObserver(
            player,
            forInterval: interval,
            queue: nil,
            using: {}
        )

        XCTAssertEqual(player.addPeriodicTimeObserverWasCalledWith?.interval, interval)
    }

    func test_addPeriodicTimeObserver_onDeInitWillCallTheRemoveTimeObserverOnPlayer() {
        let interval = CMTimeMake(value: 100, timescale: 200)
        subject.addPeriodicTimeObserver(
            player,
            forInterval: interval,
            queue: nil,
            using: {}
        )

        subject = nil

        XCTAssertNotNil(player.removeTimeObserverWasCalledWithObserver)
    }

    // MARK: - addStoppedPlaybackObserver

    func test_addStoppedPlaybackObserver_willCallAddObserverOnNotificationCenterWithExpectedValues() {
        subject.addStoppedPlaybackObserver(queue: nil, using: { _ in })

        XCTAssertEqual(
            notificationCenter.addObserverWasCalledWith?.name,
            NSNotification.Name.AVPlayerItemDidPlayToEndTime
        )
    }

    func test_addStoppedPlaybackObserver_onDeInitWillCallRemoveObserverOnNotificationCenter() {
        subject.addStoppedPlaybackObserver(queue: nil, using: { _ in })

        subject = nil

        XCTAssertNotNil(notificationCenter.removeObserverWasCalledWith)
    }
}

extension StreamPlayerObserver_Tests {
    private class MockAVPlayer: AVPlayer {
        private(set) var addPeriodicTimeObserverWasCalledWith: (interval: CMTime, block: (CMTime) -> Void)?

        private(set) var removeTimeObserverWasCalledWithObserver: Any?

        override func addPeriodicTimeObserver(
            forInterval interval: CMTime,
            queue: DispatchQueue?,
            using block: @escaping (CMTime) -> Void
        ) -> Any {
            addPeriodicTimeObserverWasCalledWith = (interval, block)
            return super.addPeriodicTimeObserver(
                forInterval: interval,
                queue: queue,
                using: block
            )
        }

        override func removeTimeObserver(
            _ observer: Any
        ) {
            removeTimeObserverWasCalledWithObserver = observer
            super.removeTimeObserver(observer)
        }
    }

    private class MockNotificationCenter: NotificationCenter {
        private(set) var addObserverWasCalledWith: (
            name: NSNotification.Name?,
            obj: Any?,
            block: (Notification) -> Void
        )?

        private(set) var removeObserverWasCalledWith: Any?

        override func addObserver(
            forName name: NSNotification.Name?,
            object obj: Any?,
            queue: OperationQueue?,
            using block: @escaping (Notification) -> Void
        ) -> NSObjectProtocol {
            addObserverWasCalledWith = (name, obj, block)
            return NSObject()
        }

        override func removeObserver(
            _ observer: Any
        ) {
            removeObserverWasCalledWith = observer
        }
    }
}
