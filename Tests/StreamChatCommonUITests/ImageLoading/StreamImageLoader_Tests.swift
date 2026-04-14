//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamImageLoader_Tests: XCTestCase {
    func test_init_defaultCDNRequester() {
        let loader = StreamImageLoader()
        XCTAssertTrue(loader.cdnRequester is StreamCDNRequester)
    }

    func test_init_customCDNRequester() {
        let cdnRequester = MockCDNRequester()
        let loader = StreamImageLoader(cdnRequester: cdnRequester)
        XCTAssertTrue(loader.cdnRequester is MockCDNRequester)
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

private final class MockCDNRequester: CDNRequester, @unchecked Sendable {
    func imageRequest(for url: URL, options: ImageRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }

    func fileRequest(for url: URL, options: FileRequestOptions, completion: @escaping (Result<CDNRequest, Error>) -> Void) {
        completion(.success(CDNRequest(url: url)))
    }
}
