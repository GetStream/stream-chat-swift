//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
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

    func test_cancelPendingDecoding_discardsQueuedWork() {
        let buffer = makeBuffer(frameCount: 6)
        buffer.updatePlaybackIndex(0)

        buffer.cancelPendingDecoding()

        XCTAssertFalse(waitForFrames(buffer, at: [0], timeout: 0.3))
        XCTAssertTrue((0..<6).allSatisfy { buffer.cachedFrame(at: $0) == nil })
    }

    func test_updatePlaybackIndex_afterCancelPendingDecoding_schedulesTheFramesAgain() {
        let buffer = makeBuffer(frameCount: 6)
        buffer.updatePlaybackIndex(0)
        buffer.cancelPendingDecoding()

        buffer.updatePlaybackIndex(0)

        XCTAssertTrue(waitForFrames(buffer, at: [0, 1, 2, 3, 4, 5]))
    }

    func test_windowIndices_listsTheUpcomingFramesBeforeTheFirstOne() {
        XCTAssertEqual(GIFFrameBuffer.windowIndices(around: 1, frameCount: 6), [1, 2, 3, 4, 0])
        XCTAssertEqual(GIFFrameBuffer.windowIndices(around: 4, frameCount: 6), [4, 5, 0, 1])
    }

    func test_init_whenTheSharedBudgetIsFull_cachesOnlyTheWindow() {
        let buffer = makeBuffer(frameCount: 6, sharedByteBudget: 1)

        buffer.updatePlaybackIndex(0)

        XCTAssertTrue(waitForFrames(buffer, at: [0, 1, 2, 3]))
        XCTAssertNil(buffer.cachedFrame(at: 4))
        XCTAssertNil(buffer.cachedFrame(at: 5))
    }

    func test_deinit_releasesTheReservedBytes() {
        let reservedBytes = AllocatedUnfairLock(0)
        var buffer: GIFFrameBuffer? = makeBuffer(frameCount: 6, sharedReservedBytes: reservedBytes)
        XCTAssertNotNil(buffer)
        XCTAssertEqual(reservedBytes.withLock { $0 }, totalBytes(frameCount: 6))

        buffer = nil

        XCTAssertEqual(reservedBytes.withLock { $0 }, 0)
    }

    func test_purge_releasesTheReservedBytes() {
        let reservedBytes = AllocatedUnfairLock(0)
        let buffer = makeBuffer(frameCount: 6, sharedReservedBytes: reservedBytes)
        XCTAssertEqual(reservedBytes.withLock { $0 }, totalBytes(frameCount: 6))

        buffer.purge(keeping: 0)

        XCTAssertEqual(reservedBytes.withLock { $0 }, 0)
    }

    // MARK: - Helpers

    private func makeBuffer(
        frameCount: Int,
        byteBudget: Int = GIFFrameBuffer.defaultByteBudget,
        sharedByteBudget: Int = 1024 * 1024,
        sharedReservedBytes: AllocatedUnfairLock<Int> = AllocatedUnfairLock(0)
    ) -> GIFFrameBuffer {
        GIFFrameBuffer(
            source: makeSource(frameCount: frameCount),
            byteBudget: byteBudget,
            sharedByteBudget: sharedByteBudget,
            sharedReservedBytes: sharedReservedBytes
        )
    }

    private func makeSource(frameCount: Int) -> GIFFrameSource {
        let data = GIFFixtures.gifData(frameDelays: Array(repeating: 0.1, count: frameCount))
        return GIFFrameSource(data: data, targetPixelSize: nil)!
    }

    private func totalBytes(frameCount: Int) -> Int {
        let source = makeSource(frameCount: frameCount)
        return source.frameCount * source.bytesPerFrame
    }

    // Waits for the given frames to finish decoding on the buffer's queue.
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
