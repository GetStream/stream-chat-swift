//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
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
}
