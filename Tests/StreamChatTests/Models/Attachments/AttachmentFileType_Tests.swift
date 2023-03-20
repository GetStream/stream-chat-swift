//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import XCTest

final class AttachmentFileType_Tests: XCTestCase {
    // MARK: - isAudio

    func test_isAudio_returnsTrueForExpectedValues() {
        let expectedValues: Set<AttachmentFileType> = [
            .mp3,
            .mp4,
            .wav,
            .ogg,
            .m4a
        ]

        AttachmentFileType.allCases.forEach { subject in
            XCTAssertEqual(subject.isAudio, expectedValues.contains(subject))
        }
    }
}
