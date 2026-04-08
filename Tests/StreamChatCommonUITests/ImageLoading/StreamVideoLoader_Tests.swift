//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamVideoLoader_Tests: XCTestCase {
    func test_init_defaultCDN() {
        let imageLoader = StreamImageLoader()
        let videoLoader = StreamVideoLoader(imageLoader: imageLoader)
        XCTAssertTrue(videoLoader.cdn is StreamCDN)
        XCTAssertTrue(videoLoader.imageLoader is StreamImageLoader)
    }

    func test_init_customCDN() {
        let cdn = MockCDN()
        let imageLoader = StreamImageLoader(cdn: cdn)
        let videoLoader = StreamVideoLoader(cdn: cdn, imageLoader: imageLoader)
        XCTAssertTrue(videoLoader.cdn is MockCDN)
    }
}

private final class MockCDN: CDN, @unchecked Sendable {
    func imageRequest(for url: URL, resize: ImageResize?, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }

    func fileRequest(for url: URL, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }
}
