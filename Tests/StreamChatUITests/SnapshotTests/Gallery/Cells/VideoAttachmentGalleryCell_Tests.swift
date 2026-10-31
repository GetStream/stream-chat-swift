//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
@testable import StreamChat
import StreamChatCommonUI
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

@MainActor final class VideoAttachmentGalleryCell_Tests: XCTestCase {
    func test_whenContentIsSet_videoLoadingComponentIsInvoked() throws {
        // Create mock components
        let components: Components = .mock

        // Create a cell and inject components
        let cell = VideoAttachmentGalleryCell()
        cell.components = components

        // Assign the content
        let url = URL.localYodaImage
        cell.content = ChatMessageVideoAttachment(
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
        ).asAnyAttachment

        // Add cell to view heirarchy to trigger lifecycle methods
        UIView().addSubview(cell)

        // Assert injected loader is invoked with correct values
        XCTAssertEqual(components.mockMediaLoader.loadVideoPreviewMockFunc.calls.map(\.0.videoURL), [url])
    }

    func test_assetLoadFailure_isRetainedAndDeliveredToCallback() {
        let loader = ControllableMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let cell = VideoAttachmentGalleryCell()
        cell.components = components

        var receivedErrors: [String] = []
        cell.onAssetLoadingErrorChange = { error in
            receivedErrors.append(error.map { String(describing: $0) } ?? "nil")
        }

        let parent = UIView()
        parent.addSubview(cell)
        cell.content = makeVideoAttachment(url: .localYodaImage).asAnyAttachment

        XCTAssertEqual(loader.pendingVideoAssets.count, 1)
        XCTAssertNil(cell.currentAssetLoadingError)
        XCTAssertNil(cell.player.currentItem)

        let error = TestError("load failed")
        loader.completeVideoAsset(at: 0, with: .failure(error))

        XCTAssertEqual(cell.currentAssetLoadingError as? TestError, error)
        XCTAssertNil(cell.player.currentItem)
        XCTAssertEqual(receivedErrors.last, String(describing: error))
    }

    func test_assetLoadFailure_beforeCallbackIsBound_isRetainedForLaterDelivery() {
        let loader = ControllableMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let cell = VideoAttachmentGalleryCell()
        cell.components = components
        let parent = UIView()
        parent.addSubview(cell)
        cell.content = makeVideoAttachment(url: .localYodaImage).asAnyAttachment

        loader.completeVideoAsset(at: 0, with: .failure(TestError("load failed")))
        XCTAssertNotNil(cell.currentAssetLoadingError)

        var receivedError: Error?
        cell.onAssetLoadingErrorChange = { receivedError = $0 }
        cell.onAssetLoadingErrorChange?(cell.currentAssetLoadingError)

        XCTAssertNotNil(receivedError)
        XCTAssertNil(cell.player.currentItem)
    }

    func test_replacingFailedAttachmentWithValidMedia_clearsErrorAndSetsPlayerItem() {
        let loader = ControllableMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let cell = VideoAttachmentGalleryCell()
        cell.components = components
        let parent = UIView()
        parent.addSubview(cell)

        let failedURL = URL.localYodaImage
        let validURL = TestImages.chewbacca.url
        cell.content = makeVideoAttachment(url: failedURL).asAnyAttachment
        loader.completeVideoAsset(at: 0, with: .failure(TestError("load failed")))
        XCTAssertNotNil(cell.currentAssetLoadingError)

        cell.content = makeVideoAttachment(url: validURL).asAnyAttachment
        XCTAssertNil(cell.currentAssetLoadingError)
        XCTAssertNil(cell.player.currentItem)

        loader.completeVideoAsset(at: 1, with: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: validURL))))
        XCTAssertNil(cell.currentAssetLoadingError)
        XCTAssertNotNil(cell.player.currentItem)
    }

    func test_prepareForReuse_clearsErrorCallbackAndPlayerItem() {
        let loader = ControllableMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let cell = VideoAttachmentGalleryCell()
        cell.components = components
        let parent = UIView()
        parent.addSubview(cell)
        cell.content = makeVideoAttachment(url: .localYodaImage).asAnyAttachment
        loader.completeVideoAsset(at: 0, with: .failure(TestError("load failed")))

        var receivedError: Error? = TestError("uncleared")
        var callbackFired = false
        cell.onAssetLoadingErrorChange = {
            callbackFired = true
            receivedError = $0
        }

        cell.prepareForReuse()

        XCTAssertTrue(callbackFired)
        XCTAssertNil(receivedError)
        XCTAssertNil(cell.onAssetLoadingErrorChange)
        XCTAssertNil(cell.currentAssetLoadingError)
        XCTAssertNil(cell.player.currentItem)
        XCTAssertNil(cell.content)
    }

    func test_staleLoaderCompletion_afterSwitchingAttachments_isIgnored() {
        let loader = ControllableMediaLoader()
        var components = Components.mock
        components.mediaLoader = loader

        let cell = VideoAttachmentGalleryCell()
        cell.components = components
        let parent = UIView()
        parent.addSubview(cell)

        let urlA = URL.localYodaImage
        let urlB = TestImages.chewbacca.url
        let attachmentA = makeVideoAttachment(url: urlA)
        let attachmentB = makeVideoAttachment(url: urlB)

        cell.content = attachmentA.asAnyAttachment
        cell.content = attachmentB.asAnyAttachment
        cell.content = attachmentA.asAnyAttachment

        XCTAssertEqual(loader.pendingVideoAssets.count, 3)
        XCTAssertNil(cell.currentAssetLoadingError)
        XCTAssertNil(cell.player.currentItem)

        loader.completeVideoAsset(at: 0, with: .failure(TestError("stale A failure")))
        XCTAssertNil(cell.currentAssetLoadingError)
        XCTAssertNil(cell.player.currentItem)

        loader.completeVideoAsset(at: 1, with: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: urlB))))
        XCTAssertNil(cell.currentAssetLoadingError)
        XCTAssertNil(cell.player.currentItem)

        loader.completeVideoAsset(at: 2, with: .success(MediaLoaderVideoAsset(asset: AVURLAsset(url: urlA))))
        XCTAssertNil(cell.currentAssetLoadingError)
        XCTAssertNotNil(cell.player.currentItem)
        XCTAssertEqual((cell.player.currentItem?.asset as? AVURLAsset)?.url, urlA)
    }

    private func makeVideoAttachment(url: URL) -> ChatMessageVideoAttachment {
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
}

private struct TestError: Error, Equatable {
    let message: String
    init(_ message: String) { self.message = message }
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
            completion(.failure(TestError("unused")))
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
            completion(.failure(TestError("unused")))
        }
    }

    func loadVideoPreview(
        at url: URL,
        options: VideoLoadOptions,
        completion: @escaping @MainActor (Result<MediaLoaderVideoPreview, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(TestError("unused")))
        }
    }

    func loadFileRequest(
        for url: URL,
        options: DownloadFileRequestOptions,
        completion: @escaping @MainActor (Result<MediaLoaderFileRequest, Error>) -> Void
    ) {
        MainActor.assumeIsolated {
            completion(.failure(TestError("unused")))
        }
    }

    @MainActor
    func completeVideoAsset(at index: Int, with result: Result<MediaLoaderVideoAsset, Error>) {
        pendingVideoAssets[index].completion(result)
    }
}
