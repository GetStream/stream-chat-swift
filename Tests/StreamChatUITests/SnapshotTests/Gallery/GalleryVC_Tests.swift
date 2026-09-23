//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
@testable import StreamChat
import StreamChatCommonUI
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

@MainActor final class GalleryVC_Tests: XCTestCase {
    private var vc: GalleryVC!
    private var content: GalleryVC.Content!
    private var retainedWindow: UIWindow?
    private var retainedViews: [UIView] = []

    override func setUp() {
        super.setUp()

        content = .init(
            message: makeMessage(with: [
                ChatMessageImageAttachment.mock(
                    id: .unique,
                    imageURL: TestImages.yoda.url
                ).asAnyAttachment,
                ChatMessageImageAttachment.mock(
                    id: .unique,
                    imageURL: TestImages.chewbacca.url
                ).asAnyAttachment
            ]),
            currentPage: 0
        )

        vc = makeGalleryVC(content: content)
        vc.showMessageTimestamp = false
    }

    override func tearDown() {
        content = nil
        vc = nil
        retainedWindow = nil
        retainedViews = []

        super.tearDown()
    }

    func test_defaultAppearance() {
        AssertSnapshot(vc)
    }

    func test_customImageAttachmentCellInjection() {
        // Declare custom image cell type
        class Cell: ImageAttachmentGalleryCell {}

        // Create components and inject custom image cell
        var components = Components.mock
        components.imageAttachmentGalleryCell = Cell.self

        // Make a gallery controller with custom components injected
        let vc = makeGalleryVC(content: content, components: components)
        vc.viewDidLoad()

        // Get the cell
        let cell = vc.collectionView(vc.attachmentsCollectionView, cellForItemAt: .init(item: 0, section: 0))

        // Assert cell is of custom type
        XCTAssertTrue(cell is Cell)
    }

    func test_customVideoAttachmentCellInjection() {
        // Declare custom video cell type
        class Cell: VideoAttachmentGalleryCell {}

        // Create components and inject custom video cell
        var components = Components.mock
        components.videoAttachmentGalleryCell = Cell.self

        // Create video attachment
        let videoAttachment = ChatMessageVideoAttachment(
            id: .unique,
            type: .video,
            payload: .init(
                title: .unique,
                videoRemoteURL: TestImages.chewbacca.url,
                file: try! .init(url: TestImages.chewbacca.url),
                extraData: nil
            ),
            downloadingState: nil,
            uploadingState: nil
        )

        // Make a gallery controller with custom components injected
        let vc = makeGalleryVC(
            content: .init(
                message: makeMessage(with: [
                    videoAttachment.asAnyAttachment,
                    videoAttachment.asAnyAttachment
                ]),
                currentPage: 0
            ),
            components: components
        )
        vc.viewDidLoad()

        // Get the cell
        let cell = vc.collectionView(vc.attachmentsCollectionView, cellForItemAt: .init(item: 0, section: 0))

        // Assert cell is of custom type
        XCTAssertTrue(cell is Cell)
    }

    func test_appearanceCustomization_usingUIConfig() {
        let appearance = Appearance()
        appearance.colorPalette.backgroundCoreElevation1 = .cyan

        vc.appearance = appearance

        AssertSnapshot(vc)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: GalleryVC {
            private lazy var customCloseButton: UIButton = {
                let button = CloseButton()
                button.setTitle("Test title", for: .normal)
                return button
            }()

            override var closeButton: UIButton { customCloseButton }
        }

        let vc = TestView()
        vc.components = .mock
        vc.content = content
        vc.showMessageTimestamp = false
        vc.loadViewIfNeeded()

        XCTAssertEqual(vc.closeButton.currentTitle, "Test title")
        XCTAssertTrue(vc.topBarContainerStackView.subviews.contains(vc.closeButton))
    }

    func test_snapshotWithMessageTimestampToday() {
        let today = Date()
        let message = makeMessage(with: [
            ChatMessageImageAttachment.mock(
                id: .unique,
                imageURL: TestImages.yoda.url
            ).asAnyAttachment
        ], createdAt: today)
        
        let content = GalleryVC.Content(message: message, currentPage: 0)
        let vc = makeGalleryVC(content: content)
        vc.showMessageTimestamp = true
        
        AssertSnapshot(vc, variants: [.defaultLight])
    }

    func test_alreadyFailedPlayerItem_stopsLoadingAndShowsAccessibleError() throws {
        let view = makePlaybackView()
        let player = AVPlayer()
        let item = ControllableStatusPlayerItem(status: .failed)
        player.replaceCurrentItem(with: item)
        view.player = player

        try waitForFailurePresentation(on: view)
        assertShowsFailure(view)
    }

    func test_playerItemTransitioningFromUnknownToFailed_showsFailureUI() throws {
        let view = makePlaybackView()
        let player = AVPlayer()
        let item = ControllableStatusPlayerItem(status: .unknown)
        player.replaceCurrentItem(with: item)
        view.player = player

        XCTAssertTrue(view.errorLabel.isHidden)

        item.transitionToFailed()
        try waitForFailurePresentation(on: view)
        assertShowsFailure(view)
    }

    func test_failedToPlayToEnd_showsFailureUI_andTimingUpdatesDoNotRestoreControls() throws {
        let view = makePlaybackView()
        let player = AVPlayer()
        let item = ControllableStatusPlayerItem(status: .unknown)
        player.replaceCurrentItem(with: item)
        view.player = player

        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            userInfo: [AVPlayerItemFailedToPlayToEndTimeErrorKey: GalleryTestError("failed to end")]
        )

        try waitForFailurePresentation(on: view)
        assertShowsFailure(view)

        view.content.videoState = .playing
        view.content.playingProgress = 0.5
        view.content.videoDuration = 12
        assertShowsFailure(view)
        XCTAssertFalse(view.loadingIndicator.isVisible)
    }

    func test_staleItemFailure_afterSwitchingItems_isIgnored() throws {
        let view = makePlaybackView()
        let player = AVPlayer()
        let itemA = ControllableStatusPlayerItem(status: .unknown)
        let itemB = ControllableStatusPlayerItem(status: .unknown)
        player.replaceCurrentItem(with: itemA)
        view.player = player

        player.replaceCurrentItem(with: itemB)

        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: itemA,
            userInfo: [AVPlayerItemFailedToPlayToEndTimeErrorKey: GalleryTestError("stale")]
        )

        XCTAssertTrue(view.errorLabel.isHidden)
        XCTAssertEqual(player.currentItem, itemB)
    }

    func test_loaderFailureBeforeGalleryBind_reachesPlaybackBar() throws {
        let loader = ImmediateFailureMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let gallery = makeGalleryVC(
            content: .init(message: makeMessage(with: [makeVideoAttachment().asAnyAttachment]), currentPage: 0),
            components: components
        )
        presentInWindow(gallery)

        assertShowsFailure(gallery.videoPlaybackBar)
        XCTAssertFalse(gallery.videoPlaybackBar.isHidden)
        XCTAssertNil(visibleVideoCell(in: gallery)?.player.currentItem)
    }

    func test_loaderFailureAfterGalleryBind_reachesPlaybackBar() throws {
        let loader = ControllableMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let gallery = makeGalleryVC(
            content: .init(message: makeMessage(with: [makeVideoAttachment().asAnyAttachment]), currentPage: 0),
            components: components
        )
        presentInWindow(gallery)

        XCTAssertTrue(gallery.videoPlaybackBar.errorLabel.isHidden)
        XCTAssertFalse(loader.pendingVideoAssets.isEmpty)

        loader.completeLastVideoAsset(with: .failure(GalleryTestError("load failed")))
        assertShowsFailure(gallery.videoPlaybackBar)
        XCTAssertNil(visibleVideoCell(in: gallery)?.player.currentItem)
    }

    func test_replacingFailedVideoWithValidVideo_clearsError() throws {
        let loader = ControllableMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let failed = makeVideoAttachment(url: .localYodaImage)
        let valid = makeVideoAttachment(url: TestImages.chewbacca.url)
        let gallery = makeGalleryVC(
            content: .init(message: makeMessage(with: [failed.asAnyAttachment, valid.asAnyAttachment]), currentPage: 0),
            components: components
        )
        presentInWindow(gallery)

        loader.completeVideoAsset(for: failed.videoURL, with: .failure(GalleryTestError("load failed")))
        assertShowsFailure(gallery.videoPlaybackBar)

        scrollGallery(gallery, to: 1)
        XCTAssertTrue(gallery.videoPlaybackBar.errorLabel.isHidden)

        loader.completeVideoAsset(for: valid.videoURL, with: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: valid.videoURL))))
        XCTAssertTrue(gallery.videoPlaybackBar.errorLabel.isHidden)
        XCTAssertTrue(gallery.videoPlaybackBar.timeSlider.isEnabled)
        XCTAssertNotNil(visibleVideoCell(in: gallery)?.player.currentItem)
    }

    func test_switchingToImage_hidesPlaybackBarAndClearsBinding() throws {
        let loader = ImmediateFailureMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let gallery = makeGalleryVC(
            content: .init(
                message: makeMessage(with: [
                    makeVideoAttachment().asAnyAttachment,
                    ChatMessageImageAttachment.mock(id: .unique, imageURL: TestImages.yoda.url).asAnyAttachment
                ]),
                currentPage: 0
            ),
            components: components
        )
        presentInWindow(gallery)
        assertShowsFailure(gallery.videoPlaybackBar)

        scrollGallery(gallery, to: 1)

        XCTAssertTrue(gallery.videoPlaybackBar.isHidden)
        XCTAssertNil(gallery.videoPlaybackBar.player)
        XCTAssertTrue(gallery.videoPlaybackBar.errorLabel.isHidden)

        scrollGallery(gallery, to: 0)
        XCTAssertFalse(gallery.videoPlaybackBar.isHidden)
        assertShowsFailure(gallery.videoPlaybackBar)
        XCTAssertNil(visibleVideoCell(in: gallery)?.player.currentItem)
    }

    func test_staleLoaderCompletionFromUnselectedCell_isIgnored() throws {
        let loader = ControllableMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let first = makeVideoAttachment(url: .localYodaImage)
        let second = makeVideoAttachment(url: TestImages.chewbacca.url)
        let gallery = makeGalleryVC(
            content: .init(message: makeMessage(with: [first.asAnyAttachment, second.asAnyAttachment]), currentPage: 0),
            components: components
        )
        presentInWindow(gallery)

        scrollGallery(gallery, to: 1)
        XCTAssertTrue(gallery.videoPlaybackBar.errorLabel.isHidden)
        XCTAssertNil(visibleVideoCell(in: gallery)?.currentAssetLoadingError)

        loader.completeVideoAsset(at: 0, with: .failure(GalleryTestError("stale cell failure")))
        XCTAssertTrue(gallery.videoPlaybackBar.errorLabel.isHidden)
        XCTAssertNil(visibleVideoCell(in: gallery)?.currentAssetLoadingError)
    }

    func test_pausedAndLoadingStates_keepNormalPlaybackControls() {
        let view = makePlaybackView()

        view.content = .init(videoDuration: 12, videoState: .paused, playingProgress: 0.25)
        XCTAssertTrue(view.errorLabel.isHidden)
        XCTAssertFalse(view.playPauseButton.isHidden)
        XCTAssertTrue(view.timeSlider.isEnabled)
        XCTAssertEqual(view.timeSlider.value, 0.25, accuracy: 0.01)

        view.content = .init(videoDuration: 12, videoState: .playing, playingProgress: 0.5)
        XCTAssertTrue(view.errorLabel.isHidden)
        XCTAssertFalse(view.playPauseButton.isHidden)
        XCTAssertTrue(view.timeSlider.isEnabled)

        view.content = .init(videoDuration: 0, videoState: .loading, playingProgress: 0)
        XCTAssertTrue(view.errorLabel.isHidden)
        XCTAssertTrue(view.playPauseButton.isHidden)
        XCTAssertTrue(view.loadingIndicator.isVisible)
        XCTAssertTrue(view.timeSlider.isEnabled)
    }

    func test_playToEndNotification_doesNotShowFailure() {
        let view = makePlaybackView()
        let player = AVPlayer()
        let item = ControllableStatusPlayerItem(status: .unknown)
        player.replaceCurrentItem(with: item)
        view.player = player

        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: item)

        XCTAssertTrue(view.errorLabel.isHidden)
        XCTAssertTrue(view.timeSlider.isEnabled)
    }

    func test_nonVideoLocalFixture_eventuallyShowsFailureUI() throws {
        let view = makePlaybackView()
        let player = AVPlayer()
        let item = AVPlayerItem(url: .localYodaImage)
        player.replaceCurrentItem(with: item)
        view.player = player

        try waitForFailurePresentation(on: view, timeout: 5)
        assertShowsFailure(view)
    }

    func test_snapshotWithMessageTimestampOlderDate() {
        let olderDate = Date(timeIntervalSince1970: 1_577_836_800)
        let message = makeMessage(with: [
            ChatMessageImageAttachment.mock(
                id: .unique,
                imageURL: TestImages.yoda.url
            ).asAnyAttachment
        ], createdAt: olderDate)
        
        let content = GalleryVC.Content(message: message, currentPage: 0)
        let vc = makeGalleryVC(content: content)
        vc.showMessageTimestamp = true
        
        AssertSnapshot(vc, variants: [.defaultLight])
    }

    private func makeGalleryVC(
        content: GalleryVC.Content,
        components: Components? = nil
    ) -> GalleryVC {
        let vc = GalleryVC()
        vc.components = components ?? .mock
        vc.content = content
        vc.attachmentsCollectionView.reloadData()
        return vc
    }

    private func makeMessage(with attachments: [AnyChatMessageAttachment], createdAt: Date = Date(timeIntervalSinceReferenceDate: 0)) -> ChatMessage {
        .mock(
            id: .unique,
            cid: .unique,
            text: "",
            author: .mock(
                id: .unique,
                name: "Author"
            ),
            createdAt: createdAt,
            attachments: attachments
        )
    }

    private func makeVideoAttachment(
        url: URL = .localYodaImage
    ) -> ChatMessageVideoAttachment {
        ChatMessageVideoAttachment(
            id: .unique,
            type: .video,
            payload: .init(
                title: .unique,
                videoRemoteURL: url,
                file: try! .init(url: url),
                extraData: nil
            ),
            downloadingState: nil,
            uploadingState: nil
        )
    }

    @discardableResult
    private func presentInWindow(_ gallery: GalleryVC) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = gallery
        window.isHidden = false
        gallery.view.frame = window.bounds
        gallery.view.layoutIfNeeded()
        gallery.updateContent()
        retainedWindow = window
        return window
    }

    private func scrollGallery(_ gallery: GalleryVC, to page: Int) {
        let width = gallery.attachmentsCollectionView.bounds.width
        gallery.attachmentsCollectionView.setContentOffset(CGPoint(x: width * CGFloat(page), y: 0), animated: false)
        gallery.attachmentsCollectionView.layoutIfNeeded()
        gallery.content.currentPage = page
    }

    private func visibleVideoCell(in gallery: GalleryVC) -> VideoAttachmentGalleryCell? {
        gallery.attachmentsCollectionView.cellForItem(at: gallery.currentItemIndexPath) as? VideoAttachmentGalleryCell
    }

    private func makePlaybackView() -> VideoPlaybackControlView {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 80))
        let view = VideoPlaybackControlView().withoutAutoresizingMaskConstraints
        parent.addSubview(view)
        view.pin(to: parent)
        parent.layoutIfNeeded()
        retainedViews.append(parent)
        return view
    }

    private func assertShowsFailure(
        _ view: VideoPlaybackControlView,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(view.errorLabel.text, L10n.Gallery.Playback.error, file: file, line: line)
        XCTAssertEqual(view.errorLabel.accessibilityLabel, L10n.Gallery.Playback.error, file: file, line: line)
        XCTAssertFalse(view.errorLabel.isHidden, file: file, line: line)
        XCTAssertTrue(view.errorLabel.isAccessibilityElement, file: file, line: line)
        XCTAssertTrue(view.errorLabel.adjustsFontForContentSizeCategory, file: file, line: line)
        XCTAssertFalse(view.loadingIndicator.isVisible, file: file, line: line)
        XCTAssertTrue(view.playPauseButton.isHidden, file: file, line: line)
        XCTAssertFalse(view.playPauseButton.isEnabled, file: file, line: line)
        XCTAssertFalse(view.timeSlider.isEnabled, file: file, line: line)
        XCTAssertTrue(view.timeSlider.isHidden, file: file, line: line)
    }

    private func waitForFailurePresentation(
        on view: VideoPlaybackControlView,
        timeout: TimeInterval = waitForTimeout
    ) throws {
        if !view.errorLabel.isHidden { return }
        let shown: Bool = try waitFor(timeout: timeout) { done in
            func poll() {
                MainActor.assumeIsolated {
                    if !view.errorLabel.isHidden {
                        done(true)
                    } else {
                        DispatchQueue.main.async(execute: poll)
                    }
                }
            }
            DispatchQueue.main.async(execute: poll)
        }
        XCTAssertTrue(shown)
    }
}

private struct GalleryTestError: Error, Equatable {
    let message: String
    init(_ message: String) { self.message = message }
}

private final class ControllableStatusPlayerItem: AVPlayerItem {
    private var forcedStatus: AVPlayerItem.Status

    override var status: AVPlayerItem.Status { forcedStatus }

    init(status: AVPlayerItem.Status) {
        forcedStatus = status
        super.init(asset: AVURLAsset(url: .localYodaImage), automaticallyLoadedAssetKeys: nil)
    }

    func transitionToFailed() {
        willChangeValue(for: \.status)
        forcedStatus = .failed
        didChangeValue(for: \.status)
    }
}

private final class ImmediateFailureMediaLoader: MediaLoader, @unchecked Sendable {
    func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("unused")))
        }
    }

    func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("load failed")))
        }
    }

    func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("unused")))
        }
    }

    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("unused")))
        }
    }

    func loadFileRequest(
        for url: URL,
        options: DownloadFileRequestOptions,
        completion: @escaping @MainActor (Result<MediaLoaderFileRequest, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("unused")))
        }
    }
}

private final class ControllableMediaLoader: MediaLoader, @unchecked Sendable {
    struct PendingVideoAsset {
        let url: URL
        let completion: @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    }

    private(set) var pendingVideoAssets: [PendingVideoAsset] = []

    func loadImage(
        url: URL?,
        options: ImageLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderImage, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("unused")))
        }
    }

    func loadVideoAsset(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoAsset, Error>) -> Void
    ) {
        pendingVideoAssets.append(.init(url: url, completion: completion))
    }

    func loadVideoPreview(
        with attachment: ChatMessageVideoAttachment,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("unused")))
        }
    }

    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("unused")))
        }
    }

    func loadFileRequest(
        for url: URL,
        options: DownloadFileRequestOptions,
        completion: @escaping @MainActor (Result<MediaLoaderFileRequest, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(GalleryTestError("unused")))
        }
    }

    @MainActor
    func completeVideoAsset(at index: Int, with result: Result<MediaLoaderVideoAsset, Error>) {
        pendingVideoAssets[index].completion(result)
    }

    @MainActor
    func completeLastVideoAsset(with result: Result<MediaLoaderVideoAsset, Error>) {
        completeVideoAsset(at: pendingVideoAssets.count - 1, with: result)
    }

    @MainActor
    func completeVideoAsset(for url: URL, with result: Result<MediaLoaderVideoAsset, Error>) {
        let index = pendingVideoAssets.lastIndex { $0.url == url }
        XCTAssertNotNil(index)
        if let index {
            completeVideoAsset(at: index, with: result)
        }
    }
}
