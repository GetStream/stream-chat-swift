//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import UIKit
import XCTest

@MainActor
final class StreamAnimatedImageEngine_Tests: XCTestCase {
    // MARK: - Loading

    func test_load_withCorruptData_returnsFalse() {
        XCTAssertFalse(StreamAnimatedImageEngine().load(data: GIFFixtures.corruptData, targetPixelSize: nil))
    }

    func test_load_withStaticImageData_returnsFalse() {
        XCTAssertFalse(StreamAnimatedImageEngine().load(data: GIFFixtures.pngData(), targetPixelSize: nil))
    }

    func test_load_withSingleFrameGIF_returnsFalse() {
        XCTAssertFalse(StreamAnimatedImageEngine().load(data: GIFFixtures.singleFrameGIFData(), targetPixelSize: nil))
    }

    func test_load_withTruncatedGIF_returnsFalse() {
        XCTAssertFalse(StreamAnimatedImageEngine().load(data: GIFFixtures.truncatedGIFData(), targetPixelSize: nil))
    }

    func test_load_withMultiFrameGIF_returnsTrue() {
        XCTAssertTrue(StreamAnimatedImageEngine().load(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]), targetPixelSize: nil))
    }

    // MARK: - Playback

    func test_play_deliversFramesInOrderAndKeepsLoopingPastTheEnd() {
        // The file asks to be played once, playback has to override that.
        let engine = makeEngine(frameCount: 2, loopCount: 1)
        var frames: [Int] = []
        let allFramesDelivered = expectation(description: "four frames delivered")
        allFramesDelivered.assertForOverFulfill = false
        engine.onFrame = { frame in
            frames.append(GIFFixtures.isFrame(frame, at: 0) ? 0 : 1)
            if frames.count == 4 {
                allFramesDelivered.fulfill()
            }
        }

        engine.play()

        wait(for: [allFramesDelivered], timeout: 5)
        XCTAssertEqual(Array(frames.prefix(4)), [0, 1, 0, 1])
    }

    func test_play_whenNothingIsLoaded_doesNothing() {
        let engine = StreamAnimatedImageEngine()

        engine.play()

        XCTAssertFalse(engine.isPlaying)
    }

    func test_play_whenAlreadyPlaying_doesNotStartASecondSession() {
        let engine = makeEngine(frameCount: 2)
        var frameCount = 0
        engine.onFrame = { _ in frameCount += 1 }

        engine.play()
        engine.play()
        wait(seconds: 0.6)

        XCTAssertTrue(engine.isPlaying)
        XCTAssertLessThan(frameCount, 9, "a second session would roughly double the frame rate")
    }

    func test_stop_preventsFurtherDelivery() {
        let engine = makeEngine(frameCount: 4)
        var frameCount = 0
        let firstFrame = expectation(description: "first frame delivered")
        firstFrame.assertForOverFulfill = false
        engine.onFrame = { _ in
            frameCount += 1
            firstFrame.fulfill()
        }
        engine.play()
        wait(for: [firstFrame], timeout: 5)

        engine.stop()
        let frameCountAtStop = frameCount
        wait(seconds: 0.5)

        XCTAssertFalse(engine.isPlaying)
        XCTAssertEqual(frameCount, frameCountAtStop)
    }

    func test_load_whilePlaying_stopsThePreviousSession() {
        let engine = makeEngine(frameCount: 4)
        var frameCount = 0
        let firstFrame = expectation(description: "first frame delivered")
        firstFrame.assertForOverFulfill = false
        engine.onFrame = { _ in
            frameCount += 1
            firstFrame.fulfill()
        }
        engine.play()
        wait(for: [firstFrame], timeout: 5)

        engine.load(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1, 0.1]), targetPixelSize: nil)
        let frameCountAtLoad = frameCount
        wait(seconds: 0.5)

        XCTAssertFalse(engine.isPlaying)
        XCTAssertEqual(frameCount, frameCountAtLoad)
    }

    func test_play_afterStop_resumesFromTheLastDeliveredFrame() throws {
        let engine = makeEngine(frameCount: 4)
        var frames: [UIImage] = []
        let secondFrame = expectation(description: "two frames delivered")
        secondFrame.assertForOverFulfill = false
        engine.onFrame = { frame in
            frames.append(frame)
            if frames.count == 2 {
                secondFrame.fulfill()
            }
        }
        engine.play()
        wait(for: [secondFrame], timeout: 5)
        engine.stop()

        let resumedFrame = expectation(description: "frame delivered after resuming")
        resumedFrame.assertForOverFulfill = false
        var resumed: UIImage?
        engine.onFrame = { frame in
            if resumed == nil {
                resumed = frame
                resumedFrame.fulfill()
            }
        }
        engine.play()
        wait(for: [resumedFrame], timeout: 5)

        XCTAssertTrue(GIFFixtures.isFrame(try XCTUnwrap(resumed), at: 1))
    }

    func test_deinit_whilePlaying_stopsTheSessionAndDeallocates() {
        var engine: StreamAnimatedImageEngine? = makeEngine(frameCount: 4)
        weak var weakEngine = engine
        let firstFrame = expectation(description: "first frame delivered")
        firstFrame.assertForOverFulfill = false
        engine?.onFrame = { _ in firstFrame.fulfill() }
        engine?.play()
        wait(for: [firstFrame], timeout: 5)

        engine = nil
        wait(seconds: 0.5)

        XCTAssertNil(weakEngine)
    }

    // MARK: - Helpers

    private func makeEngine(frameCount: Int, loopCount: Int = 0) -> StreamAnimatedImageEngine {
        let engine = StreamAnimatedImageEngine()
        let data = GIFFixtures.gifData(
            frameDelays: Array(repeating: 0.1, count: frameCount),
            loopCount: loopCount
        )
        XCTAssertTrue(engine.load(data: data, targetPixelSize: nil))
        return engine
    }

    /// Keeps the run loop going, so ImageIO can deliver frames on the main queue.
    private func wait(seconds: TimeInterval) {
        let settled = expectation(description: "waited \(seconds)s")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            settled.fulfill()
        }
        wait(for: [settled], timeout: seconds + 2)
    }
}
