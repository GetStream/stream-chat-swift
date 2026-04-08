//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamImageLoader_Tests: XCTestCase {
    func test_init_defaultCDN() {
        let loader = StreamImageLoader()
        XCTAssertTrue(loader.cdn is StreamCDN)
    }

    func test_init_customCDN() {
        let cdn = MockCDN()
        let loader = StreamImageLoader(cdn: cdn)
        XCTAssertTrue(loader.cdn is MockCDN)
    }

    func test_loadImage_nilURL_callsCompletionWithFailure() {
        let loader = StreamImageLoader()
        let expectation = expectation(description: "Completion called")

        loader.loadImage(url: nil, resize: nil) { result in
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

private final class MockCDN: CDN, @unchecked Sendable {
    func imageRequest(for url: URL, resize: ImageResize?, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }

    func fileRequest(for url: URL, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }
}
