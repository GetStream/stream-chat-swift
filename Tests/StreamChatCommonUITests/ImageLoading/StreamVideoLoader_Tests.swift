//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamVideoLoader_Tests: XCTestCase {
    func test_init_defaultCDNRequester() {
        let imageLoader = StreamImageLoader()
        let videoLoader = StreamVideoLoader(imageLoader: imageLoader)
        XCTAssertTrue(videoLoader.cdnRequester is StreamCDNRequester)
        XCTAssertTrue(videoLoader.imageLoader is StreamImageLoader)
    }

    func test_init_customCDNRequester() {
        let cdnRequester = MockCDNRequester()
        let imageLoader = StreamImageLoader(cdnRequester: cdnRequester)
        let videoLoader = StreamVideoLoader(cdnRequester: cdnRequester, imageLoader: imageLoader)
        XCTAssertTrue(videoLoader.cdnRequester is MockCDNRequester)
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
