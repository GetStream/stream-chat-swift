//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class TextLinkDetector_Tests: XCTestCase {
    func test_hasLinks_whenContainsLinks_thenReturnsTrue() {
        let sut = TextLinkDetector()
        let text = "Hey www.google.com"
        XCTAssertTrue(sut.hasLinks(in: text))
    }

    func test_hasLinks_whenNoLinks_thenReturnsFalse() {
        let sut = TextLinkDetector()
        let text = "Hey"
        XCTAssertFalse(sut.hasLinks(in: text))
    }

    func test_firstLink_whenContainsLinks_thenReturnsFirstLink() {
        let sut = TextLinkDetector()
        let text = "Hey www.google.com www.youtube.com"
        let firstLink = sut.firstLink(in: text)
        XCTAssertEqual(firstLink?.url.absoluteString, "http://www.google.com")
        XCTAssertEqual(firstLink?.originalText, "www.google.com")
        XCTAssertEqual(firstLink?.range, NSRange(location: 4, length: 14))
    }

    func test_firstLink_whenNoLinks_thenReturnsNil() {
        let sut = TextLinkDetector()
        let text = "Hey"
        let firstLink = sut.firstLink(in: text)
        XCTAssertNil(firstLink)
    }

    func test_links_whenContainsLinks_thenReturnsAllLinks() {
        let sut = TextLinkDetector()
        let text = "Hey www.google.com www.youtube.com"
        let expectedLinks: [TextLink] = [
            .init(
                url: URL(string: "http://www.google.com")!,
                originalText: "www.google.com",
                range: NSRange(location: 4, length: 14)
            ),
            .init(
                url: URL(string: "http://www.youtube.com")!,
                originalText: "www.youtube.com",
                range: NSRange(location: 19, length: 15)
            )
        ]
        XCTAssertEqual(sut.links(in: text), expectedLinks)
    }

    func test_links_whenNoLinks_thenReturnsEmpty() {
        let sut = TextLinkDetector()
        let text = "Hey"
        XCTAssertTrue(sut.links(in: text).isEmpty)
    }
}
