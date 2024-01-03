//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

final class StreamAudioSessionFeedbackGenerator_Tests: XCTestCase {
    private lazy var lightImpactFeedbackGenerator: SpyUIImpactFeedbackGenerator! = .init()
    private lazy var mediumImpactFeedbackGenerator: SpyUIImpactFeedbackGenerator! = .init()
    private lazy var heavyImpactFeedbackGenerator: SpyUIImpactFeedbackGenerator! = .init()
    private lazy var selectionFeedbackGenerator: SpyUISelectionFeedbackGenerator! = .init()
    private lazy var audioSessionFeedbackGenerator: StreamAudioSessionFeedbackGenerator! = makeAudioSessionFeedbackGenerator()

    override func tearDown() {
        lightImpactFeedbackGenerator = nil
        mediumImpactFeedbackGenerator = nil
        heavyImpactFeedbackGenerator = nil
        selectionFeedbackGenerator = nil
        audioSessionFeedbackGenerator = nil
        super.tearDown()
    }

    // MARK: - feedbackForPlay

    func test_feedbackForPlay_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForPlay(),
            expectedCalledFeedbackGenerator: lightImpactFeedbackGenerator
        )
    }

    // MARK: - feedbackForPause

    func test_feedbackForPause_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForPause(),
            expectedCalledFeedbackGenerator: lightImpactFeedbackGenerator
        )
    }

    // MARK: - feedbackForStop

    func test_feedbackForStop_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForStop(),
            expectedCalledFeedbackGenerator: mediumImpactFeedbackGenerator
        )
    }

    // MARK: - feedbackForPlaybackRateChange

    func test_feedbackForPlaybackRateChange_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForPlaybackRateChange(),
            expectedCalledFeedbackGenerator: mediumImpactFeedbackGenerator
        )
    }

    // MARK: - feedbackForSeeking

    func test_feedbackForSeeking_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForSeeking(),
            expectedCalledFeedbackGenerator: selectionFeedbackGenerator
        )
    }

    // MARK: - feedbackForPreparingRecording

    func test_feedbackForPreparingRecording_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForPreparingRecording(),
            expectedCalledFeedbackGenerator: lightImpactFeedbackGenerator
        )
    }

    // MARK: - feedbackForBeginRecording

    func test_feedbackForBeginRecording_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForBeginRecording(),
            expectedCalledFeedbackGenerator: mediumImpactFeedbackGenerator
        )
    }

    // MARK: - feedbackForCancelRecording

    func test_feedbackForCancelRecording_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForCancelRecording(),
            expectedCalledFeedbackGenerator: heavyImpactFeedbackGenerator
        )
    }

    // MARK: - feedbackForStopRecording

    func test_feedbackForStopRecording_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForStopRecording(),
            expectedCalledFeedbackGenerator: mediumImpactFeedbackGenerator
        )
    }

    // MARK: - feedbackForDiscardRecording

    func test_feedbackForDiscardRecording_callsExpectedFeedbackGenerator() throws {
        try assertFeedbackGenerator(
            audioSessionFeedbackGenerator.feedbackForDiscardRecording(),
            expectedCalledFeedbackGenerator: heavyImpactFeedbackGenerator
        )
    }

    // MARK: - Private Helpers

    func makeAudioSessionFeedbackGenerator() -> StreamAudioSessionFeedbackGenerator {
        .init(
            { feedbackStyle in
                switch feedbackStyle {
                case .light:
                    return lightImpactFeedbackGenerator
                case .medium:
                    return mediumImpactFeedbackGenerator
                case .heavy:
                    return heavyImpactFeedbackGenerator
                case .soft:
                    XCTFail()
                    return lightImpactFeedbackGenerator
                case .rigid:
                    XCTFail()
                    return lightImpactFeedbackGenerator
                @unknown default:
                    XCTFail()
                    return lightImpactFeedbackGenerator
                }
            },
            selectionFeedbackGeneratorProvider: { selectionFeedbackGenerator }
        )
    }

    func assertFeedbackGenerator(
        _ action: @autoclosure () -> Void,
        expectedCalledFeedbackGenerator: @autoclosure () -> UIFeedbackGenerator,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        action()
        let feedbackGenerators = [
            lightImpactFeedbackGenerator,
            mediumImpactFeedbackGenerator,
            heavyImpactFeedbackGenerator,
            selectionFeedbackGenerator
        ]

        let feedbackGeneratorToCheck = try XCTUnwrap(
            feedbackGenerators.first { $0 === expectedCalledFeedbackGenerator() }.map { $0 as? Spy },
            file: file,
            line: line
        )

        XCTAssertEqual(feedbackGeneratorToCheck?.recordedFunctions.count, 1)

        feedbackGenerators
            .filter { $0 !== expectedCalledFeedbackGenerator() }
            .map { $0 as? Spy }
            .forEach { XCTAssertEqual($0?.recordedFunctions.count, 0, file: file, line: line) }
    }
}

private final class SpyUIImpactFeedbackGenerator: UIImpactFeedbackGenerator, Spy {
    var recordedFunctions: [String] = []

    override func impactOccurred() {
        record()
    }
}

private final class SpyUISelectionFeedbackGenerator: UISelectionFeedbackGenerator, Spy {
    var recordedFunctions: [String] = []

    override func selectionChanged() {
        record()
    }
}
