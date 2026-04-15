//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
import XCTest

final class StreamMediaLoader_VideoTests: XCTestCase {
    func test_init_setsDownloader() {
        let downloader = MockImageDownloader()
        let loader = StreamMediaLoader(downloader: downloader)
        XCTAssertTrue(loader.downloader is MockImageDownloader)
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
