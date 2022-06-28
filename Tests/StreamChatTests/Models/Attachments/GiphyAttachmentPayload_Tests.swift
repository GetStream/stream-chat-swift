//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class GiphyAttachmentPayload_Tests: XCTestCase {
    let giphyURL: URL = URL(string: "https://media2.giphy.com/media/SY9klAvBdbcPiQGfdN/giphy.gif?cid=c4b03675cvbts7fssybzy83bdtpfr21jpcekvcto96i1vjk5&rid=giphy.gif&ct=g")!
    let title = "title"

    var sut: GiphyAttachmentPayload?

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func test_ItInitializesPayloadWithGivenData() {
        // WHEN
        sut = GiphyAttachmentPayload(
            title: title,
            previewURL: giphyURL,
            actions: []
        )

        // THEN
        XCTAssertEqual(sut?.title, title)
        XCTAssertEqual(sut?.previewURL, giphyURL)
        XCTAssertEqual(sut?.actions, [])
    }
}
