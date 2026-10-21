//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import UIKit
import XCTest

final class AIMessageAttachment_Tests: XCTestCase {
    private let pdf = URL(string: "https://example.com/files/itinerary.pdf")!

    func test_initURL_isAnImage_forAnImageFile() {
        XCTAssertEqual(AIMessageAttachment(url: URL(fileURLWithPath: "/tmp/photo.HEIC")).kind, .image)
    }

    func test_initURL_isAFile_forAnyOtherFile() {
        XCTAssertEqual(AIMessageAttachment(url: pdf).kind, .file)
        XCTAssertEqual(
            AIMessageAttachment(url: URL(fileURLWithPath: "/tmp/logo.svg")).kind,
            .file,
            "images load as bitmaps, which a vector image is not"
        )
    }

    func test_initURL_readsTheMediaType_overTheExtension() {
        let upload = URL(string: "https://example.com/uploads/7f3a")!
        XCTAssertEqual(AIMessageAttachment(url: upload, mimeType: "image/png").kind, .image)
    }

    func test_kind_isOpen() {
        let location: AIMessageAttachment.Kind = "location"
        let attachment = AIMessageAttachment(kind: location, extraData: ["latitude": 38.72])
        XCTAssertEqual(attachment.kind.rawValue, "location")
        XCTAssertEqual(attachment.extraData["latitude"], 38.72)
    }

    func test_displayName_isItsName_thenItsFileName() {
        XCTAssertEqual(AIMessageAttachment.file(pdf, name: "Lisbon trip.pdf").displayName, "Lisbon trip.pdf")
        XCTAssertEqual(AIMessageAttachment.file(pdf).displayName, "itinerary.pdf")
    }

    func test_displayName_saysWhatItIs_withoutAName() {
        XCTAssertEqual(AIMessageAttachment.image(UIImage()).displayName, "Image")
        XCTAssertEqual(AIMessageAttachment(kind: .file).displayName, "File")
    }

    func test_details_isTheTypeAndTheSize() {
        let size = ByteCountFormatter.string(fromByteCount: 2_400_000, countStyle: .file)
        XCTAssertEqual(AIMessageAttachment.file(pdf, size: 2_400_000).details, "PDF · \(size)")
        XCTAssertEqual(AIMessageAttachment.file(pdf).details, "PDF")
        XCTAssertEqual(AIMessageAttachment(kind: .file, size: 2_400_000).details, size)
        XCTAssertEqual(AIMessageAttachment(kind: .file).details, "")
    }

    func test_details_readsTheType_fromTheMediaType_withoutAnExtension() {
        let upload = URL(string: "https://example.com/uploads/7f3a")!
        XCTAssertEqual(AIMessageAttachment.file(upload, mimeType: "application/pdf").details, "PDF")
    }
}
