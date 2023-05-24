//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat
import XCTest

final class AVAssetTotalAudioSamples_Tests: XCTestCase {
    // MARK: - Properties

    private lazy var audioFilePath = Bundle(for: type(of: self))
        .path(forResource: "test_audio_file", ofType: "m4a")!
    private var audioFile: AVAsset!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        audioFile = AVAsset(url: .init(fileURLWithPath: audioFilePath))
    }

    override func tearDown() {
        audioFile = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testBufferReturnsWaveformData() throws {
        let expectedSampleCount = 10_770_718

        let totalSamples = audioFile.totalSamplesOfFirstAudioTrack()

        XCTAssertEqual(totalSamples, expectedSampleCount, "Asset should have \(expectedSampleCount) samples")
    }
}
