//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat
import XCTest

final class AVAudioFileBuffer_Tests: XCTestCase {
    // MARK: - Properties

    private lazy var audioFilePath = Bundle(for: type(of: self))
        .path(forResource: "test_audio_file", ofType: "m4a")!
    private var audioFile: AVAudioFile!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        do {
            audioFile = try AVAudioFile(forReading: URL(fileURLWithPath: audioFilePath))
        } catch {
            XCTFail("Error initializing AVAudioFile: \(error)")
        }
    }

    override func tearDown() {
        audioFile = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testBufferReturnsWaveformData() throws {
        // Given
        let expectedChannelCount = 2
        let expectedFrameCount = 5_384_301

        // When
        let buffer = try audioFile.buffer()

        // Then
        XCTAssertEqual(buffer.count, expectedChannelCount, "Buffer should have \(expectedChannelCount) channels")
        XCTAssertEqual(buffer[0].count, expectedFrameCount, "Buffer should have \(expectedFrameCount) frames")
        XCTAssertEqual(buffer[1].count, expectedFrameCount, "Buffer should have \(expectedFrameCount) frames")
    }
}
