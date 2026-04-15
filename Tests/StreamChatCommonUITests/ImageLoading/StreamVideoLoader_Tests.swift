//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamVideoLoader_Tests: XCTestCase {
    func test_init_setsImageLoader() {
        let downloader = MockImageDownloader()
        let imageLoader = StreamImageLoader(downloader: downloader)
        let videoLoader = StreamVideoLoader(imageLoader: imageLoader)
        XCTAssertTrue(videoLoader.imageLoader is StreamImageLoader)
    }
}

private final class MockCDNRequester: CDNRequester, @unchecked Sendable {
    func imageRequest(for url: URL, options: ImageRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }

    func fileRequest(for url: URL, options: FileRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }
}

private final class MockImageDownloader: ImageDownloading, @unchecked Sendable {
    func downloadImage(
        url: URL,
        headers: [String: String]?,
        cachingKey: String?,
        resize: CGSize?,
        completion: @escaping @MainActor (Result<UIImage, Error>) -> Void
    ) {
        DispatchQueue.main.async {
            completion(.failure(NSError(domain: "MockImageDownloader", code: 0)))
        }
    }
}
