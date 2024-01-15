//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
@testable import StreamChatUI
import XCTest

final class StreamImageCDN_Tests: XCTestCase {
    let baseUrl = "https://www.\(StreamImageCDN.streamCDNURL)"

    func test_cachingKey_whenHostIsNotStreamCDN() {
        let streamCDN = StreamImageCDN()

        let url = URL(string: "https://www.google.com/image.jpg?someStuff=20")!
        let key = streamCDN.cachingKey(forImageUrl: url)

        XCTAssertEqual(key, "https://www.google.com/image.jpg?someStuff=20")
    }

    func test_cachingKey_shouldRemoveUnwantedQueryParameters() {
        let streamCDN = StreamImageCDN()

        let url = URL(string: "\(baseUrl)/image.jpg?name=Luke&father=Anakin")!
        let filteredUrl = "\(baseUrl)/image.jpg"
        let key = streamCDN.cachingKey(forImageUrl: url)

        XCTAssertEqual(key, filteredUrl)
    }

    func test_cachingKey_shouldFilterWantedQueryParameters() {
        let streamCDN = StreamImageCDN()

        let url = URL(string: "\(baseUrl)/image.jpg?name=Luke&w=128&h=128&crop=center&resize=crop&ro=0")!
        let filteredUrl = "\(baseUrl)/image.jpg?w=128&h=128&crop=center&resize=crop"
        let key = streamCDN.cachingKey(forImageUrl: url)

        XCTAssertEqual(key, filteredUrl)
    }

    func test_cachingKey_whenThereIsNoQueryParameters() {
        let streamCDN = StreamImageCDN()

        let url = URL(string: "\(baseUrl)/image.jpg")!
        let key = streamCDN.cachingKey(forImageUrl: url)

        XCTAssertEqual(key, "\(baseUrl)/image.jpg")
    }

    func test_urlRequest_whenHostIsNotStreamCDN() {
        let streamCDN = StreamImageCDN()

        let url = URL(string: "https://www.google.com/image.jpg?someStuff=20")!
        let processedURLRequest = streamCDN.urlRequest(
            forImageUrl: url,
            resize: .init(CGSize(width: 40, height: 40))
        )

        XCTAssertEqual(
            processedURLRequest.url,
            URL(string: "https://www.google.com/image.jpg?someStuff=20")!
        )
    }

    func test_urlRequest_whenThereAreNoResizeOptions() {
        let streamCDN = StreamImageCDN()

        let url = URL(string: "\(baseUrl)/image.jpg")!

        let processedURLRequest = streamCDN.urlRequest(
            forImageUrl: url,
            resize: nil
        )

        XCTAssertEqual(
            processedURLRequest.url,
            URL(string: "\(baseUrl)/image.jpg")!
        )
    }

    func test_urlRequest_whenThereAreResizeQueryParameters() {
        let streamCDN = StreamImageCDN()

        let url = URL(string: "\(baseUrl)/image.jpg")!

        let processedURLRequest = streamCDN.urlRequest(
            forImageUrl: url,
            resize: ImageResize(
                CGSize(width: 40, height: 60),
                mode: .crop(.center)
            )
        )

        let w: Int = Int(40 * UIScreen.main.scale)
        let h: Int = Int(60 * UIScreen.main.scale)

        AssertEqualURL(
            processedURLRequest.url!,
            URL(string: "\(baseUrl)/image.jpg?w=\(w)&h=\(h)&crop=center&resize=crop&ro=0")!
        )
    }

    func test_urlRequest_whenResizeIsNotCrop_shouldNotIncludeCropKey() {
        let streamCDN = StreamImageCDN()

        let url = URL(string: "\(baseUrl)/image.jpg")!

        let processedURLRequest = streamCDN.urlRequest(
            forImageUrl: url,
            resize: ImageResize(
                CGSize(width: 40, height: 60),
                mode: .fill
            )
        )

        let w: Int = Int(40 * UIScreen.main.scale)
        let h: Int = Int(60 * UIScreen.main.scale)

        AssertEqualURL(
            processedURLRequest.url!,
            URL(string: "\(baseUrl)/image.jpg?w=\(w)&h=\(h)&resize=fill&ro=0")!
        )
    }

    private func AssertEqualURL(_ lhs: URL, _ rhs: URL) {
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
