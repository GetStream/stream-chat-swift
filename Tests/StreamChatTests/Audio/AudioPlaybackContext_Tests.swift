//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class AudioPlaybackContext_Tests: XCTestCase {
    private var context: AudioPlaybackContext!

    override func setUpWithError() throws {
        context = AudioPlaybackContext(
            duration: 100,
            currentTime: 50,
            state: .playing,
            rate: .normal,
            isSeeking: false
        )
    }

    override func tearDownWithError() throws {
        context = nil
        try super.tearDownWithError()
    }

    // MARK: - init

    func test_init_wasConfiguredCorrectly() throws {
        XCTAssertEqual(context.duration, 100)
        XCTAssertEqual(context.currentTime, 50)
        XCTAssertEqual(context.state, .playing)
        XCTAssertEqual(context.rate, .normal)
        XCTAssertFalse(context.isSeeking)
    }

    // MARK: - notLoaded

    func test_notLoaded_wasConfiguredCorrectly() throws {
        let notLoadedContext = AudioPlaybackContext.notLoaded

        XCTAssertEqual(notLoadedContext.duration, 0)
        XCTAssertEqual(notLoadedContext.currentTime, 0)
        XCTAssertEqual(notLoadedContext.state, .notLoaded)
        XCTAssertEqual(notLoadedContext.rate, .zero)
        XCTAssertFalse(notLoadedContext.isSeeking)
    }

    // MARK: - isEqual

    func test_isEqual_returnsExpectedResults() throws {
        let context2 = AudioPlaybackContext(
            duration: 100,
            currentTime: 50,
            state: .playing,
            rate: .normal,
            isSeeking: false
        )
        XCTAssertEqual(context, context2)

        let context3 = AudioPlaybackContext(
            duration: 100,
            currentTime: 50,
            state: .paused,
            rate: .normal,
            isSeeking: false
        )
        XCTAssertNotEqual(context, context3)
    }
}
