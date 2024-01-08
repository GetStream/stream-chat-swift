//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class AudioSamplesProcessor_Tests: XCTestCase {
    private lazy var subject: AudioSamplesProcessor! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - processSamples(fromData:outputSamples:samplesToProcess:downSampledLength:downsamplingRate:filter:)

    func test_processSamples_withEmptyData_returnsExpectedResult() {
        var data = Data()
        var outputSamples = [Float]()

        subject.processSamples(
            fromData: &data,
            outputSamples: &outputSamples,
            samplesToProcess: 0,
            downSampledLength: 0,
            downsamplingRate: 0,
            filter: []
        )

        XCTAssertEqual(outputSamples.count, 0)
    }

    func test_processSamples_withZeroSamplesToProcess_returnsExpectedResult() {
        var data = Data(repeating: 0, count: 4)
        var outputSamples = [Float]()

        subject.processSamples(
            fromData: &data,
            outputSamples: &outputSamples,
            samplesToProcess: 0,
            downSampledLength: 0,
            downsamplingRate: 0,
            filter: []
        )

        XCTAssertEqual(outputSamples.count, 0)
    }

    func test_processSamples_withLargeSampleBuffer_returnsExpectedResult() {
        var data = Data(repeating: 0, count: 16)
        var outputSamples = [Float]()

        subject.processSamples(
            fromData: &data,
            outputSamples: &outputSamples,
            samplesToProcess: 4,
            downSampledLength: 2,
            downsamplingRate: 2,
            filter: [0.5, 0.5]
        )

        XCTAssertEqual(outputSamples, [subject.noiseFloor, subject.noiseFloor])
    }

    func test_processSamples_withNonZeroDownsamplingRate_returnsExpectedResult() {
        var data = Data(repeating: 0, count: 8)
        var outputSamples = [Float]()

        subject.processSamples(
            fromData: &data,
            outputSamples: &outputSamples,
            samplesToProcess: 4,
            downSampledLength: 2,
            downsamplingRate: 2,
            filter: [0.5, 0.5]
        )

        XCTAssertEqual(outputSamples, [subject.noiseFloor, subject.noiseFloor])
    }

    func test_processSamples_withNonUnityFilter_returnsExpectedResult() {
        var data = Data(repeating: 0, count: 8)
        var outputSamples = [Float]()

        subject.processSamples(
            fromData: &data,
            outputSamples: &outputSamples,
            samplesToProcess: 4,
            downSampledLength: 2,
            downsamplingRate: 2,
            filter: [0.25, 0.5, 0.25]
        )

        let expectedValue = subject.noiseFloor - (subject.noiseFloor / 4)
        XCTAssertEqual(outputSamples, [expectedValue, expectedValue])
    }
}
