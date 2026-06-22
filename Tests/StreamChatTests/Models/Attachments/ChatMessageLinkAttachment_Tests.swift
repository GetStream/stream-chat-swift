//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatMessageLinkAttachment_Tests: XCTestCase {
    func test_hasValidURL_whenTitleLinkIsMissingInPayload() {
        // GIVEN
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadLink_without_title_link")

        do {
            // WHEN
            let payload = try JSONDecoder.default.decode(LinkAttachmentPayload.self, from: json)

            // THEN
            XCTAssertEqual(payload.originalURL, URL(string: "google.com"))
            XCTAssertNil(payload.titleLink)
            XCTAssertEqual(payload.url.absoluteString, "http://google.com")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_hasValidURL_whenTitleLinkIsInPayload() {
        // GIVEN
        let json = XCTestCase.mockData(fromJSONFile: "AttachmentPayloadLink_with_title_link")

        do {
            // WHEN
            let payload = try JSONDecoder.default.decode(LinkAttachmentPayload.self, from: json)

            // THEN
            let expectedURL = URL(string: "https://www.google.com")
            XCTAssertEqual(payload.originalURL, expectedURL)
            XCTAssertEqual(payload.titleLink, expectedURL)
            XCTAssertEqual(payload.url.absoluteString, "https://www.google.com")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - GetOGResponse.asModel()

    func test_asModel_mapsAllFields() throws {
        let response = GetOGResponse.dummy(
            authorName: "Stream",
            imageUrl: "https://getstream.io/image.jpg",
            ogScrapeUrl: "https://getstream.io",
            text: "\nText\n",
            thumbUrl: "https://getstream.io/thumb.jpg",
            title: "  Title  ",
            titleLink: "https://getstream.io/link"
        )

        let payload = try response.asModel()

        XCTAssertEqual(payload.originalURL, URL(string: "https://getstream.io"))
        // `title` and `text` are trimmed of surrounding whitespace.
        XCTAssertEqual(payload.title, "Title")
        XCTAssertEqual(payload.text, "Text")
        XCTAssertEqual(payload.author, "Stream")
        XCTAssertEqual(payload.titleLink, URL(string: "https://getstream.io/link"))
        XCTAssertEqual(payload.assetURL, URL(string: "https://getstream.io/image.jpg"))
        XCTAssertEqual(payload.previewURL, URL(string: "https://getstream.io/thumb.jpg"))
    }

    func test_asModel_assetURLFallsBackToAssetUrl_whenImageURLMissing() throws {
        let response = GetOGResponse.dummy(assetUrl: "https://getstream.io/asset.mp4")

        let payload = try response.asModel()

        XCTAssertEqual(payload.assetURL, URL(string: "https://getstream.io/asset.mp4"))
    }

    func test_asModel_previewURLFallsBackToAssetURL_whenThumbMissing() throws {
        let response = GetOGResponse.dummy(imageUrl: "https://getstream.io/image.jpg")

        let payload = try response.asModel()

        XCTAssertEqual(payload.previewURL, URL(string: "https://getstream.io/image.jpg"))
    }

    func test_asModel_throws_whenOGScrapeURLIsMissing() {
        let response = GetOGResponse.dummy(ogScrapeUrl: nil)

        XCTAssertThrowsError(try response.asModel())
    }
}
