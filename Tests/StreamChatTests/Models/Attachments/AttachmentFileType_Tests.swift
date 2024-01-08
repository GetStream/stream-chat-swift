//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

final class AttachmentFileType_Tests: XCTestCase {
    // MARK: - isAudio

    func test_isAudio_returnsTrueForExpectedValues() {
        let expectedValues: Set<AttachmentFileType> = [
            .mp3,
            .wav,
            .ogg,
            .m4a,
            .aac
        ]

        AttachmentFileType.allCases.forEach { subject in
            XCTAssertEqual(subject.isAudio, expectedValues.contains(subject))
        }
    }

    func test_isUnknown() {
        XCTAssertEqual(AttachmentFileType.aac.isUnknown, false)
        XCTAssertEqual(AttachmentFileType.doc.isUnknown, false)
        XCTAssertEqual(AttachmentFileType.generic.isUnknown, false)
        XCTAssertEqual(AttachmentFileType.unknown.isUnknown, true)
    }
}
