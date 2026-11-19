//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import UIKit
import XCTest

@MainActor
final class StreamAnimatedImageView_Tests: XCTestCase {
    private var engine: AnimatedImageEngine_Mock!
    private var view: StreamAnimatedImageView!
    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        engine = AnimatedImageEngine_Mock()
        view = StreamAnimatedImageView()
        view.engine = engine
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.isHidden = false
    }

    override func tearDown() {
        engine = nil
        view = nil
        window = nil
        super.tearDown()
    }

    // MARK: - Loading

    func test_setAnimatedImage_loadsDataAndShowsPosterFrame() {
        let data = GIFFixtures.gifData(frameDelays: [0.1, 0.1])

        let didLoad = view.setAnimatedImage(data: data)

        XCTAssertTrue(didLoad)
        XCTAssertEqual(engine.loadedData, [data])
        XCTAssertEqual(view.animatedImageData, data)
        XCTAssertNotNil(view.image)
    }

    func test_setAnimatedImage_whenFallbackImageIsProvided_showsIt() {
        let fallback = GIFFixtures.solidColorImage(size: CGSize(width: 4, height: 4), color: .green)

        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]), fallbackImage: fallback)

        XCTAssertEqual(view.image, fallback)
    }

    func test_setAnimatedImage_whenEngineCannotLoad_keepsFallbackAsStaticImage() {
        engine.loadResult = false
        let fallback = GIFFixtures.solidColorImage(size: CGSize(width: 4, height: 4), color: .green)

        let didLoad = view.setAnimatedImage(data: GIFFixtures.pngData(), fallbackImage: fallback)

        XCTAssertFalse(didLoad)
        XCTAssertNil(view.animatedImageData)
        XCTAssertEqual(view.image, fallback)
        XCTAssertEqual(engine.playCallCount, 0)
    }

    func test_setAnimatedImage_whenDataIsUnchanged_doesNotReload() {
        let data = GIFFixtures.gifData(frameDelays: [0.1, 0.1])
        window.addSubview(view)
        view.setAnimatedImage(data: data)

        view.setAnimatedImage(data: data)

        XCTAssertEqual(engine.loadCallCount, 1)
        XCTAssertEqual(engine.playCallCount, 1)
    }

    func test_setAnimatedImage_afterStopAnimating_withSameData_resumesPlayback() {
        let data = GIFFixtures.gifData(frameDelays: [0.1, 0.1])
        window.addSubview(view)
        view.setAnimatedImage(data: data)
        view.stopAnimating()

        let didLoad = view.setAnimatedImage(data: data)

        XCTAssertTrue(didLoad)
        XCTAssertEqual(engine.loadCallCount, 1)
        XCTAssertEqual(engine.playCallCount, 2)
    }

    func test_setAnimatedImage_whenDataPreviouslyFailedToLoad_doesNotReload() {
        engine.loadResult = false
        let data = GIFFixtures.pngData()
        XCTAssertFalse(view.setAnimatedImage(data: data))

        let didLoad = view.setAnimatedImage(data: data)

        XCTAssertFalse(didLoad)
        XCTAssertEqual(engine.loadCallCount, 1)
    }

    func test_setAnimatedImage_whenDataChanges_reloads() {
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.2, 0.2, 0.2]))

        XCTAssertEqual(engine.loadCallCount, 2)
        XCTAssertEqual(engine.playCallCount, 2)
    }

    func test_onFrame_updatesImage() {
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))
        let frame = GIFFixtures.solidColorImage(size: CGSize(width: 4, height: 4), color: .blue)

        engine.deliver(frame: frame)

        XCTAssertEqual(view.image, frame)
    }

    func test_clearAnimatedImage_unloadsTheAnimationAndKeepsImage() {
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))
        let visibleImage = view.image

        view.clearAnimatedImage()

        XCTAssertEqual(engine.unloadCallCount, 1)
        XCTAssertNil(view.animatedImageData)
        XCTAssertEqual(view.image, visibleImage)
    }

    // MARK: - Playback gating

    func test_setAnimatedImage_whenNotInWindow_doesNotPlay() {
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        XCTAssertEqual(engine.playCallCount, 0)
    }

    func test_whenAddedToWindow_playsLoadedAnimation() {
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        window.addSubview(view)

        XCTAssertEqual(engine.playCallCount, 1)
    }

    func test_whenRemovedFromWindow_stopsAndResumesOnReattach() {
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        view.removeFromSuperview()
        XCTAssertEqual(engine.stopCallCount, 1)

        window.addSubview(view)
        XCTAssertEqual(engine.playCallCount, 2)
    }

    func test_stopAnimating_stickAcrossWindowReattach() {
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        view.stopAnimating()
        view.removeFromSuperview()
        window.addSubview(view)

        XCTAssertEqual(engine.playCallCount, 1)
    }

    func test_startAnimating_afterStopAnimating_resumesPlayback() {
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))
        view.stopAnimating()

        view.startAnimating()

        XCTAssertEqual(engine.playCallCount, 2)
    }

    func test_startAnimating_withoutAnimatedData_fallsBackToUIImageView() {
        window.addSubview(view)
        view.animationImages = [GIFFixtures.solidColorImage(size: CGSize(width: 4, height: 4), color: .red)]

        view.startAnimating()

        XCTAssertEqual(engine.playCallCount, 0)
        XCTAssertTrue(view.isAnimating)
    }

    func test_isAnimating_isNotAffectedByEnginePlayback() {
        // UIImageView consults `isAnimating` when rendering `image`: reporting `true` while
        // the engine delivers frames makes UIKit ignore the updates and freeze on screen.
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))
        XCTAssertTrue(engine.isPlaying)

        XCTAssertFalse(view.isAnimating)
    }

    // MARK: - Visibility

    func test_visibilityCheck_whenOnScreen_isTrue() {
        view.frame = CGRect(x: 10, y: 10, width: 20, height: 20)
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        XCTAssertEqual(engine.visibilityCheck?(), true)
    }

    func test_visibilityCheck_whenAnAncestorIsHidden_isFalse() {
        let container = UIView(frame: window.bounds)
        view.frame = CGRect(x: 10, y: 10, width: 20, height: 20)
        window.addSubview(container)
        container.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        container.isHidden = true

        XCTAssertEqual(engine.visibilityCheck?(), false)
    }

    func test_visibilityCheck_whenScrolledOffScreen_isFalse() {
        view.frame = CGRect(x: 10, y: 200, width: 20, height: 20)
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        XCTAssertEqual(engine.visibilityCheck?(), false)
    }

    func test_visibilityCheck_whenNotInWindow_isFalse() {
        view.frame = CGRect(x: 10, y: 10, width: 20, height: 20)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        XCTAssertEqual(engine.visibilityCheck?(), false)
    }

    // MARK: - Application state

    func test_whenApplicationEntersBackground_stopsAndResumesOnForeground() {
        window.addSubview(view)
        view.setAnimatedImage(data: GIFFixtures.gifData(frameDelays: [0.1, 0.1]))

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertEqual(engine.stopCallCount, 1)

        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        XCTAssertEqual(engine.playCallCount, 2)
    }
}
