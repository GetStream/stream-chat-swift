//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import UIKit
import XCTest

@MainActor
final class StreamAnimatedImage_Tests: XCTestCase {
    func test_makeView_appliesLayoutConfiguration() {
        let view = StreamAnimatedImage(data: nil, contentMode: .scaleAspectFill).makeView()

        XCTAssertTrue(view.clipsToBounds)
        XCTAssertEqual(view.contentMode, .scaleAspectFill)
        XCTAssertEqual(view.contentHuggingPriority(for: .horizontal), .defaultLow)
        XCTAssertEqual(view.contentHuggingPriority(for: .vertical), .defaultLow)
        XCTAssertEqual(view.contentCompressionResistancePriority(for: .horizontal), .defaultLow)
        XCTAssertEqual(view.contentCompressionResistancePriority(for: .vertical), .defaultLow)
    }

    func test_apply_withSameDataTwice_loadsOnce() {
        let engine = AnimatedImageEngine_Mock()
        let view = StreamAnimatedImage(data: nil).makeView()
        view.engine = engine
        let data = GIFFixtures.gifData(frameDelays: [0.1, 0.1])
        let sut = StreamAnimatedImage(data: data)

        sut.apply(to: view)
        sut.apply(to: view)

        XCTAssertEqual(engine.loadCallCount, 1)
    }

    func test_apply_withSameNonAnimatableDataTwice_loadsOnce() {
        let engine = AnimatedImageEngine_Mock()
        engine.loadResult = false
        let view = StreamAnimatedImage(data: nil).makeView()
        view.engine = engine
        let sut = StreamAnimatedImage(data: GIFFixtures.pngData())

        sut.apply(to: view)
        sut.apply(to: view)

        XCTAssertEqual(engine.loadCallCount, 1)
    }

    func test_apply_withNilData_clearsAnimation() {
        let engine = AnimatedImageEngine_Mock()
        let view = StreamAnimatedImage(data: nil).makeView()
        view.engine = engine
        StreamAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1])).apply(to: view)

        StreamAnimatedImage(data: nil).apply(to: view)

        XCTAssertNil(view.animatedImageData)
        XCTAssertNil(view.image)
        XCTAssertEqual(engine.stopCallCount, 1)
    }
}
