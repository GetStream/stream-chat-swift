//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

final class DefaultAudioRecordingNameFormatter_Tests: XCTestCase {
    private lazy var subject: DefaultAudioRecordingNameFormatter! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - title(forItemAtURL:index:)

    func test_title_indexIs0_returnsExpectedResult() {
        assertTitleAtIndex(0)
    }

    func test_title_indexIs1_returnsExpectedResult() {
        assertTitleAtIndex(1)
    }

    // MARK: - Private Helpers

    private func assertTitleAtIndex(
        _ index: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expected = index == 0 ? "Recording" : "Recording(\(index))"

        let actual = subject.title(forItemAtURL: .unique(), index: index)

        XCTAssertEqual(expected, actual, file: file, line: line)
    }
}
