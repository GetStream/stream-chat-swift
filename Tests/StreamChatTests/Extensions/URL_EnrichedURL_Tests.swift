//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class URL_EnrichedURL_Tests: XCTestCase {
    func test_schemeIsAdded_whenMissing() {
        // GIVEN
        let url = URL(string: "google.com")

        // THEN
        XCTAssertEqual(url?.enrichedURL.absoluteString, "http://google.com")
    }

    func test_urlWithSchemeIsNotChanged_whenHavingScheme() {
        // GIVEN
        let url = URL(string: "https://google.com")

        // THEN
        XCTAssertEqual(url?.enrichedURL, url)
    }
}
