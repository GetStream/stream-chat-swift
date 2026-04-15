//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamImageLoader_Tests: XCTestCase {
    func test_loadImage_nilURL_callsCompletionWithFailure() {
        let downloader = MockImageDownloader()
        let loader = StreamImageLoader(downloader: downloader)
        let cdnRequester = MockCDNRequester()
        let expectation = expectation(description: "Completion called")

        loader.loadImage(url: nil, options: ImageLoadOptions(cdnRequester: cdnRequester)) { result in
            switch result {
            case .failure:
                break
            case .success:
                XCTFail("Should have failed for nil URL")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2)
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
