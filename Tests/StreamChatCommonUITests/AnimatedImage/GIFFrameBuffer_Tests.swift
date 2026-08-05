//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import UIKit
import XCTest

final class GIFFrameBuffer_Tests: XCTestCase {
    func test_updatePlaybackIndex_whenAnimationFitsTheBudget_cachesEveryFrame() {
        let buffer = makeBuffer(frameCount: 6)

        buffer.updatePlaybackIndex(0)

        XCTAssertTrue(waitForFrames(buffer, at: [0, 1, 2, 3, 4, 5]))
    }

    func test_updatePlaybackIndex_whenAnimationExceedsTheBudget_cachesOnlyTheWindow() {
        let buffer = makeBuffer(frameCount: 6, byteBudget: 1)

        buffer.updatePlaybackIndex(0)

        XCTAssertTrue(waitForFrames(buffer, at: [0, 1, 2, 3]))
        XCTAssertNil(buffer.cachedFrame(at: 4))
        XCTAssertNil(buffer.cachedFrame(at: 5))
    }

    func test_updatePlaybackIndex_whenTheWindowMoves_evictsPassedFramesAndKeepsTheFirstOne() {
        let buffer = makeBuffer(frameCount: 6, byteBudget: 1)
        buffer.updatePlaybackIndex(0)
        XCTAssertTrue(waitForFrames(buffer, at: [0, 1, 2, 3]))

        buffer.updatePlaybackIndex(3)

        XCTAssertTrue(waitForFrames(buffer, at: [0, 3, 4, 5]))
        XCTAssertNil(buffer.cachedFrame(at: 1))
        XCTAssertNil(buffer.cachedFrame(at: 2))
    }

    func test_purge_keepsOnlyTheGivenFrame() {
        let buffer = makeBuffer(frameCount: 6)
        buffer.updatePlaybackIndex(0)
        XCTAssertTrue(waitForFrames(buffer, at: [0, 1, 2, 3, 4, 5]))

        buffer.purge(keeping: 2)

        XCTAssertNotNil(buffer.cachedFrame(at: 2))
        for index in [0, 1, 3, 4, 5] {
            XCTAssertNil(buffer.cachedFrame(at: index), "frame \(index) should have been purged")
        }
    }

    func test_purge_stopsCachingTheWholeAnimation() {
        let buffer = makeBuffer(frameCount: 6)
        buffer.updatePlaybackIndex(0)
        XCTAssertTrue(waitForFrames(buffer, at: [0, 1, 2, 3, 4, 5]))
        buffer.purge(keeping: 0)

        buffer.updatePlaybackIndex(0)

        XCTAssertTrue(waitForFrames(buffer, at: [0, 1, 2, 3]))
        XCTAssertNil(buffer.cachedFrame(at: 4))
        XCTAssertNil(buffer.cachedFrame(at: 5))
    }

    // MARK: - Helpers

    private func makeBuffer(frameCount: Int, byteBudget: Int = GIFFrameBuffer.defaultByteBudget) -> GIFFrameBuffer {
        let data = GIFFixtures.gifData(frameDelays: Array(repeating: 0.1, count: frameCount))
        let source = GIFFrameSource(data: data, targetPixelSize: nil)!
        return GIFFrameBuffer(source: source, byteBudget: byteBudget)
    }

    /// Waits for the given frames to finish decoding on the buffer's queue.
    private func waitForFrames(_ buffer: GIFFrameBuffer, at indices: [Int], timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if indices.allSatisfy({ buffer.cachedFrame(at: $0) != nil }) {
                return true
            }
            Thread.sleep(forTimeInterval: 0.01)
        }
        return false
    }
}
