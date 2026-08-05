//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import UIKit
import XCTest

final class GIFFrameSource_Tests: XCTestCase {
    func test_init_withCorruptData_returnsNil() {
        XCTAssertNil(GIFFrameSource(data: GIFFixtures.corruptData, targetPixelSize: nil))
    }

    func test_init_withStaticImageData_returnsNil() {
        XCTAssertNil(GIFFrameSource(data: GIFFixtures.pngData(), targetPixelSize: nil))
    }

    func test_init_parsesFrameCount() {
        let source = GIFFrameSource(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1, 0.1]), targetPixelSize: nil)

        XCTAssertEqual(source?.frameCount, 3)
    }

    func test_frameDelays_replaceUnusableDelaysWithTheDefault() {
        let source = GIFFrameSource(data: GIFFixtures.gifData(frameDelays: [0, 0.25, 0.02]), targetPixelSize: nil)

        XCTAssertEqual(source?.frameDelays ?? [], [0.1, 0.25, 0.02])
    }

    func test_loopCount_whenFileSpecifiesIt_isParsed() {
        let infinite = GIFFrameSource(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1], loopCount: 0), targetPixelSize: nil)
        let finite = GIFFrameSource(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1], loopCount: 5), targetPixelSize: nil)

        XCTAssertEqual(infinite?.loopCount, 0)
        XCTAssertEqual(finite?.loopCount, 5)
    }

    func test_loopCount_whenFileHasNoLoopingExtension_isOne() {
        let source = GIFFrameSource(data: GIFFixtures.gifDataWithoutLoopExtension, targetPixelSize: nil)

        XCTAssertEqual(source?.frameCount, 2)
        XCTAssertEqual(source?.loopCount, 1)
    }

    func test_decodeFrame_returnsTheFrameAtTheGivenIndex() {
        let source = GIFFrameSource(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1, 0.1]), targetPixelSize: nil)

        let frames = (0..<3).compactMap { source?.decodeFrame(at: $0) }

        XCTAssertEqual(frames.count, 3)
        for (index, frame) in frames.enumerated() {
            XCTAssertTrue(GIFFixtures.isFrame(frame, at: index), "frame \(index) has unexpected pixels")
        }
    }

    func test_decodeFrame_withIndexOutOfBounds_returnsNil() {
        let source = GIFFrameSource(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]), targetPixelSize: nil)

        XCTAssertNil(source?.decodeFrame(at: -1))
        XCTAssertNil(source?.decodeFrame(at: 2))
    }

    func test_decodeFrame_withSmallerTargetSize_downsamples() {
        let data = GIFFixtures.gifData(frameDelays: [0.1, 0.1], size: CGSize(width: 40, height: 20))
        let source = GIFFrameSource(data: data, targetPixelSize: CGSize(width: 20, height: 20))

        XCTAssertEqual(source?.decodeFrame(at: 0)?.size, CGSize(width: 20, height: 10))
    }

    func test_decodeFrame_withLargerTargetSize_doesNotUpscale() {
        let data = GIFFixtures.gifData(frameDelays: [0.1, 0.1], size: CGSize(width: 40, height: 20))
        let source = GIFFrameSource(data: data, targetPixelSize: CGSize(width: 400, height: 400))

        XCTAssertEqual(source?.decodeFrame(at: 0)?.size, CGSize(width: 40, height: 20))
    }

    func test_bytesPerFrame_matchesTheDecodedSize() {
        let data = GIFFixtures.gifData(frameDelays: [0.1, 0.1], size: CGSize(width: 40, height: 20))

        let native = GIFFrameSource(data: data, targetPixelSize: nil)
        let downsampled = GIFFrameSource(data: data, targetPixelSize: CGSize(width: 20, height: 20))

        XCTAssertEqual(native?.bytesPerFrame, 40 * 20 * 4)
        XCTAssertEqual(downsampled?.bytesPerFrame, 20 * 10 * 4)
    }
}
