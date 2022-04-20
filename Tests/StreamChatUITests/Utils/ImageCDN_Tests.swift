//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
@testable import StreamChatUI
import XCTest

final class ImageCDN_Tests: XCTestCase {
    func test_cache_validStreamURL_filtered() {
        let provider = StreamImageCDN()
        
        let url = URL(string: "https://wwww.stream-io-cdn.com/image.jpg?name=Luke&father=Anakin")!
        let filteredUrl = "https://wwww.stream-io-cdn.com/image.jpg"
        let key = provider.cachingKey(forImage: url)
        
        XCTAssertEqual(key, filteredUrl)
    }
    
    func test_cache_validStreamUrl_withSizeParameters() {
        let provider = StreamImageCDN()
        
        let url = URL(string: "https://wwww.stream-io-cdn.com/image.jpg?name=Luke&w=128&h=128&crop=center&resize=fill&ro=0")!
        let filteredUrl = "https://wwww.stream-io-cdn.com/image.jpg?w=128&h=128"
        let key = provider.cachingKey(forImage: url)
        
        XCTAssertEqual(key, filteredUrl)
    }
    
    func test_cache_validStreamURL_unchanged() {
        let provider = StreamImageCDN()
        
        let url = URL(string: "https://wwww.stream-io-cdn.com/image.jpg")!
        let key = provider.cachingKey(forImage: url)
        
        XCTAssertEqual(key, url.absoluteString)
    }
    
    func test_cache_validURL_unchanged() {
        let provider = StreamImageCDN()
        
        let url = URL(string: "https://wwww.stream.io")!
        let key = provider.cachingKey(forImage: url)
        
        XCTAssertEqual(key, url.absoluteString)
    }
    
    func test_cache_invalidURL_unchanged() {
        let provider = StreamImageCDN()
        
        let url1 = URL(string: "https://abc")!
        let key1 = provider.cachingKey(forImage: url1)
        
        let url2 = URL(string: "abc.def")!
        let key2 = provider.cachingKey(forImage: url2)
        
        XCTAssertEqual(key1, url1.absoluteString)
        XCTAssertEqual(key2, url2.absoluteString)
    }
    
    func test_thumbnail_validStreamUrl_withoutParameters() {
        let provider = StreamImageCDN()
        
        let url = URL(string: "https://wwww.stream-io-cdn.com/image.jpg")!
        let size = Int(40 * UIScreen.main.scale)
        let thumbnailUrl = URL(string: "https://wwww.stream-io-cdn.com/image.jpg?w=\(size)&h=\(size)&crop=center&resize=fill&ro=0")!
        let processedURL = provider.thumbnailURL(
            originalURL: url,
            preferredSize: CGSize(width: 40, height: 40)
        )
        
        assertEqualURL(processedURL, thumbnailUrl)
    }
    
    func test_thumbnail_validStreamUrl_withParameters() {
        let provider = StreamImageCDN()
        
        let url = URL(string: "https://wwww.stream-io-cdn.com/image.jpg?name=Luke")!
        let size = Int(40 * UIScreen.main.scale)
        let thumbnailUrl =
            URL(string: "https://wwww.stream-io-cdn.com/image.jpg?name=Luke&w=\(size)&h=\(size)&crop=center&resize=fill&ro=0")!
        let processedURL = provider.thumbnailURL(
            originalURL: url,
            preferredSize: CGSize(width: 40, height: 40)
        )
        
        assertEqualURL(processedURL, thumbnailUrl)
    }
    
    func test_thumbnail_validURL_unchanged() {
        let provider = StreamImageCDN()
        
        let url = URL(string: "https://wwww.stream.io")!
        let processedURL = provider.thumbnailURL(
            originalURL: url,
            preferredSize: CGSize(width: 40, height: 40)
        )
        
        XCTAssertEqual(processedURL, url)
    }

    private func assertEqualURL(_ lhs: URL, _ rhs: URL) {
        guard var lhsComponents = URLComponents(url: lhs, resolvingAgainstBaseURL: true),
              var rhsComponents = URLComponents(url: rhs, resolvingAgainstBaseURL: true) else {
            XCTFail("Unexpected url")
            return
        }

        // Because query paramters can be placed in a different order, we need to check it key by key.
        var lhsParameters: [String: String] = [:]
        lhsComponents.queryItems?.forEach {
            lhsParameters[$0.name] = $0.value
        }

        var rhsParameters: [String: String] = [:]
        rhsComponents.queryItems?.forEach {
            rhsParameters[$0.name] = $0.value
        }

        XCTAssertEqual(lhsParameters.count, rhsParameters.count)

        lhsParameters.forEach { key, lValue in
            XCTAssertEqual(lValue, rhsParameters[key])
        }

        lhsComponents.query = nil
        rhsComponents.query = nil
        XCTAssertEqual(lhsComponents.url, rhsComponents.url)
    }
}
