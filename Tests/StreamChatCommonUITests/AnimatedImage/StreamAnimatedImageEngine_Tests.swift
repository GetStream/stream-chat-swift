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

    // MARK: - Helpers

    private func makeEngine(frameCount: Int) -> StreamAnimatedImageEngine {
        let engine = StreamAnimatedImageEngine()
        let data = GIFFixtures.gifData(frameDelays: Array(repeating: 0.1, count: frameCount))
        XCTAssertTrue(engine.load(data: data, targetPixelSize: nil))
        return engine
    }

    /// Advances playback and keeps retrying until the frame it should show is decoded.
    ///
    /// Frames are decoded off the main thread, so a tick that arrives before the next frame is
    /// ready holds the current one and delivers as soon as decoding finishes.
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

    /// Gives the buffer time to decode the frames of a small fixture.
    private func waitForDecoding() {
        Thread.sleep(forTimeInterval: 0.3)
    }
}
