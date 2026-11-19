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

    func test_load_whilePlaying_stopsPlayback() {
        let engine = makeEngine(frameCount: 3)
        engine.play()
        XCTAssertTrue(engine.isPlaying)

        engine.load(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]), targetPixelSize: nil)

        XCTAssertFalse(engine.isPlaying)
    }

    func test_load_doesNotDecodeFramesBeforePlayback() {
        let engine = makeEngine(frameCount: 3)
        waitForDecoding()
        var delivered: UIImage?
        engine.onFrame = { delivered = $0 }

        engine.play()
        engine.advance(by: 0)

        XCTAssertNil(delivered)
    }

    func test_unload_stopsPlaybackAndDiscardsTheAnimation() {
        let engine = makeEngine(frameCount: 3)
        engine.play()

        engine.unload()
        engine.play()

        XCTAssertFalse(engine.isPlaying)
    }

    // MARK: - Playback

    func test_play_deliversTheFirstFrameOnceItIsDecoded() {
        let engine = makeEngine(frameCount: 3)

        engine.play()

        let frame = advanceUntilFrameIsDelivered(engine, by: 0)
        XCTAssertNotNil(frame)
        XCTAssertTrue(GIFFixtures.isFrame(frame!, at: 0))
    }

    func test_advance_withDeltaBelowTheFrameDelay_doesNotDeliverTheNextFrame() {
        let engine = makeEngine(frameCount: 3)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))
        waitForDecoding()

        var delivered: UIImage?
        engine.onFrame = { delivered = $0 }
        engine.advance(by: 0.05)

        XCTAssertNil(delivered)
    }

    func test_advance_withDeltaAtTheFrameDelay_deliversTheNextFrame() {
        let engine = makeEngine(frameCount: 3)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))

        let frame = advanceUntilFrameIsDelivered(engine, by: 0.1)

        XCTAssertNotNil(frame)
        XCTAssertTrue(GIFFixtures.isFrame(frame!, at: 1))
    }

    func test_advance_withALargeDelta_deliversOnlyTheFrameToCatchUpTo() {
        let engine = makeEngine(frameCount: 5)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))
        waitForDecoding()

        var delivered: [UIImage] = []
        engine.onFrame = { delivered.append($0) }
        engine.advance(by: 0.35)

        XCTAssertEqual(delivered.count, 1)
        XCTAssertTrue(delivered.first.map { GIFFixtures.isFrame($0, at: 3) } ?? false)
    }

    func test_advance_afterTheLastFrame_wrapsToTheFirstOne() {
        let engine = makeEngine(frameCount: 2)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0.1))

        let frame = advanceUntilFrameIsDelivered(engine, by: 0.1)

        XCTAssertNotNil(frame)
        XCTAssertTrue(GIFFixtures.isFrame(frame!, at: 0))
    }

    func test_advance_afterStop_doesNotDeliverFrames() {
        let engine = makeEngine(frameCount: 3)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))
        waitForDecoding()

        engine.stop()
        var delivered: UIImage?
        engine.onFrame = { delivered = $0 }
        engine.advance(by: 1)

        XCTAssertFalse(engine.isPlaying)
        XCTAssertNil(delivered)
    }

    func test_play_afterStop_resumesFromTheCurrentFrame() {
        let engine = makeEngine(frameCount: 3)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0.1))
        engine.stop()

        engine.play()
        let frame = advanceUntilFrameIsDelivered(engine, by: 0.1)

        XCTAssertNotNil(frame)
        XCTAssertTrue(GIFFixtures.isFrame(frame!, at: 2))
    }

    func test_play_whenNothingIsLoaded_doesNothing() {
        let engine = StreamAnimatedImageEngine()

        engine.play()

        XCTAssertFalse(engine.isPlaying)
    }

    // MARK: - Ticks

    func test_handleTick_advancesByTheTimeSinceThePreviousTick() {
        let engine = makeEngine(frameCount: 5)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))
        waitForDecoding()
        var delivered: [UIImage] = []
        engine.onFrame = { delivered.append($0) }

        engine.handleTick(timestamp: 10)
        engine.handleTick(timestamp: 10.35)

        XCTAssertEqual(delivered.count, 1)
        XCTAssertTrue(delivered.first.map { GIFFixtures.isFrame($0, at: 3) } ?? false)
    }

    func test_handleTick_whileInvisible_doesNotAdvance() {
        let engine = makeEngine(frameCount: 5)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))
        waitForDecoding()
        var delivered: [UIImage] = []
        engine.onFrame = { delivered.append($0) }
        engine.visibilityCheck = { false }

        engine.handleTick(timestamp: 10)
        engine.handleTick(timestamp: 10.35)

        XCTAssertTrue(delivered.isEmpty)
    }

    func test_handleTick_whileInvisible_doesNotDecode() {
        let engine = makeEngine(frameCount: 3)
        engine.visibilityCheck = { false }
        engine.play()
        engine.handleTick(timestamp: 10)
        waitForDecoding()
        var delivered: UIImage?
        engine.onFrame = { delivered = $0 }
        engine.visibilityCheck = { true }

        engine.handleTick(timestamp: 10.1)

        XCTAssertNil(delivered)
    }

    func test_handleTick_afterBecomingVisible_resumesWithoutSkippingFrames() {
        let engine = makeEngine(frameCount: 5)
        engine.play()
        XCTAssertNotNil(advanceUntilFrameIsDelivered(engine, by: 0))
        waitForDecoding()
        var delivered: [UIImage] = []
        engine.onFrame = { delivered.append($0) }
        engine.visibilityCheck = { false }
        engine.handleTick(timestamp: 10)
        engine.visibilityCheck = { true }

        engine.handleTick(timestamp: 13)
        engine.handleTick(timestamp: 13.15)

        XCTAssertEqual(delivered.count, 1)
        XCTAssertTrue(delivered.first.map { GIFFixtures.isFrame($0, at: 1) } ?? false)
    }

    // MARK: - Helpers

    private func makeEngine(frameCount: Int) -> StreamAnimatedImageEngine {
        let engine = StreamAnimatedImageEngine()
        let data = GIFFixtures.gifData(frameDelays: Array(repeating: 0.1, count: frameCount))
        XCTAssertTrue(engine.load(data: data, targetPixelSize: nil))
        return engine
    }

    // Frames are decoded off the main thread, so this keeps advancing by zero until the frame
    // that `delta` leads to is decoded and delivered.
    private func advanceUntilFrameIsDelivered(
        _ engine: StreamAnimatedImageEngine,
        by delta: TimeInterval,
        timeout: TimeInterval = 5
    ) -> UIImage? {
        var delivered: UIImage?
        engine.onFrame = { delivered = $0 }
        engine.advance(by: delta)
        let deadline = Date().addingTimeInterval(timeout)
        while delivered == nil, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
            engine.advance(by: 0)
        }
        engine.onFrame = nil
        return delivered
    }

    private func waitForDecoding() {
        Thread.sleep(forTimeInterval: 0.3)
    }
}
