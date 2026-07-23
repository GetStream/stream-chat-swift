//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class AttributedString_Links_Tests: XCTestCase {
    // MARK: - NSMutableAttributedString

    func test_addLinks_whenPlainTextURL_addsLinkAttribute() {
        let detector = TextLinkDetector()
        let attributedText = NSMutableAttributedString(string: "visit https://getstream.io now")

        attributedText.addLinks(detectedBy: detector)

        XCTAssertEqual(firstLink(in: attributedText), URL(string: "https://getstream.io"))
    }

    func test_addLinks_whenExistingLink_preservesIt() {
        let detector = TextLinkDetector()
        let realURL = URL(string: "https://real-link.com")!
        let attributedText = NSMutableAttributedString(string: "https://text-link.com")
        attributedText.addAttribute(
            .link,
            value: realURL,
            range: NSRange(location: 0, length: attributedText.length)
        )

        attributedText.addLinks(detectedBy: detector)

        XCTAssertEqual(firstLink(in: attributedText), realURL)
    }

    func test_addLinks_whenNoLinks_doesNotAddAttribute() {
        let detector = TextLinkDetector()
        let attributedText = NSMutableAttributedString(string: "Hey there")

        attributedText.addLinks(detectedBy: detector)

        XCTAssertNil(firstLink(in: attributedText))
    }

    // MARK: - AttributedString

    @available(iOS 15, *)
    func test_addLinks_attributedString_whenPlainTextURL_addsLinkAttribute() {
        let detector = TextLinkDetector()
        var attributedString = AttributedString("visit https://getstream.io now")

        attributedString.addLinks(detectedBy: detector)

        XCTAssertEqual(firstLink(in: attributedString), URL(string: "https://getstream.io"))
    }

    @available(iOS 15, *)
    func test_addLinks_attributedString_whenExistingLink_preservesIt() {
        let detector = TextLinkDetector()
        let realURL = URL(string: "https://real-link.com")!
        var attributedString = AttributedString("https://text-link.com")
        attributedString.link = realURL

        attributedString.addLinks(detectedBy: detector)

        XCTAssertEqual(firstLink(in: attributedString), realURL)
    }

    @available(iOS 15, *)
    func test_addLinks_attributedString_whenNoLinks_doesNotAddAttribute() {
        let detector = TextLinkDetector()
        var attributedString = AttributedString("Hey there")

        attributedString.addLinks(detectedBy: detector)

        XCTAssertNil(firstLink(in: attributedString))
    }

    // MARK: - Helpers

    private func firstLink(in attributedText: NSAttributedString) -> URL? {
        var foundLink: URL?
        attributedText.enumerateAttribute(
            .link,
            in: NSRange(location: 0, length: attributedText.length)
        ) { value, _, stop in
            if let url = value as? URL {
                foundLink = url
                stop.pointee = true
            }
        }
        return foundLink
    }

    @available(iOS 15, *)
    private func firstLink(in attributedString: AttributedString) -> URL? {
        for (value, _) in attributedString.runs[\.link] where value != nil {
            return value
        }
        return nil
    }
}
