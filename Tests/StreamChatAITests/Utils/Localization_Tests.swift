//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class Localization_Tests: XCTestCase {
    func test_strings_areReadFromTheSDKBundle() {
        XCTAssertEqual(L10n.Composer.placeholderAskAnything, "Ask anything")
        XCTAssertEqual(L10n.Composer.buttonAllPhotos, "All Photos")
        XCTAssertEqual(L10n.StreamingMessage.codeBlockLanguageFallback, "plain text")
        XCTAssertEqual(L10n.Reasoning.thinking, "Thinking…")
        XCTAssertEqual(L10n.Reasoning.thought, "Thought process")
        XCTAssertEqual(L10n.Reasoning.showHint, "Shows the model's reasoning.")
        XCTAssertEqual(L10n.Reasoning.hideHint, "Hides the model's reasoning.")
        XCTAssertEqual(L10n.ToolCall.awaitingClient, "Waiting for the device")
        XCTAssertEqual(L10n.ToolCall.awaitingApproval, "Waiting for approval")
        XCTAssertEqual(L10n.ToolCall.declined, "Declined")
        XCTAssertEqual(L10n.ToolCall.failed, "Didn't complete")
        XCTAssertEqual(L10n.ToolCall.cancelled, "Cancelled")
        XCTAssertEqual(L10n.ToolCall.unsupported, "A step this app version can't show")
        XCTAssertEqual(L10n.ToolApproval.allow, "Allow")
        XCTAssertEqual(L10n.ToolApproval.decline, "Don't Allow")
        XCTAssertEqual(L10n.ToolApproval.notSent, "Your answer couldn't be sent. Try again.")
        XCTAssertEqual(L10n.Transcription.recognizerUnavailable, "Speech recognizer is unavailable.")
    }

    func test_formattedStrings_insertTheDuration() {
        XCTAssertEqual(L10n.Reasoning.thinkingFor("7s"), "Thinking… 7s")
        XCTAssertEqual(L10n.Reasoning.thoughtFor("12s"), "Thought for 12s")
    }

    func test_speechHandlerError_isDescribedWithLocalizedText() {
        XCTAssertEqual(SpeechHandlerError.recognizerUnavailable.errorDescription, L10n.Transcription.recognizerUnavailable)
    }
}
