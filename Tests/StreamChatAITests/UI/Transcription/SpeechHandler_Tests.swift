//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Speech
@testable import StreamChatAI
import XCTest

@MainActor
final class SpeechHandler_Tests: XCTestCase {
    private struct ActivationError: Error {}

    private let system = SpeechSystemFake()
    private lazy var handler = SpeechHandler(system: system)

    // MARK: - Permissions

    func test_start_whenThePersonAllowsSpeechRecognition_asksForTheMicrophone() {
        system.speechAuthorization = .notDetermined
        system.microphonePermission = .undetermined

        handler.start()
        XCTAssertEqual(system.speechAuthorizationRequests.count, 1)
        system.answerSpeechAuthorization(.authorized)

        XCTAssertEqual(system.microphonePermissionRequests.count, 1)
        XCTAssertEqual(handler.authorizationStatus, .authorized)
    }

    func test_start_whenThePersonDeniesSpeechRecognitionTheFirstTime_saysWhy() {
        system.speechAuthorization = .notDetermined

        handler.start()
        system.answerSpeechAuthorization(.denied)

        XCTAssertEqual(handler.lastError as? SpeechHandlerError, .speechRecognitionDenied)
        XCTAssertEqual(handler.authorizationStatus, .denied)
        XCTAssertTrue(system.microphonePermissionRequests.isEmpty)
        XCTAssertTrue(system.activations.isEmpty)
    }

    func test_start_whenSpeechRecognitionIsDenied_saysWhy() {
        system.speechAuthorization = .denied

        handler.start()

        XCTAssertEqual(handler.lastError as? SpeechHandlerError, .speechRecognitionDenied)
        XCTAssertTrue(system.speechAuthorizationRequests.isEmpty)
        XCTAssertTrue(system.activations.isEmpty)
    }

    func test_start_whenThePersonAllowsTheMicrophone_activatesTheAudioSession() {
        system.microphonePermission = .undetermined

        handler.start()
        system.answerMicrophonePermission(true)

        XCTAssertEqual(system.activations.count, 1)
        XCTAssertNil(handler.lastError)
    }

    func test_start_whenThePersonDeniesTheMicrophone_saysWhy() {
        system.microphonePermission = .undetermined

        handler.start()
        system.answerMicrophonePermission(false)

        XCTAssertEqual(handler.lastError as? SpeechHandlerError, .microphoneDenied)
        XCTAssertTrue(system.activations.isEmpty)
    }

    func test_start_whenTheMicrophoneIsDenied_saysWhy() {
        system.microphonePermission = .denied

        handler.start()

        XCTAssertEqual(handler.lastError as? SpeechHandlerError, .microphoneDenied)
        XCTAssertTrue(system.microphonePermissionRequests.isEmpty)
        XCTAssertTrue(system.activations.isEmpty)
    }

    func test_start_whileItStarts_asksOnce() {
        system.microphonePermission = .undetermined

        handler.start()
        handler.start()

        XCTAssertEqual(system.microphonePermissionRequests.count, 1)
    }

    // MARK: - Stopping while it starts

    func test_stop_whileSpeechRecognitionIsAsked_ignoresTheAnswer() {
        system.speechAuthorization = .notDetermined
        system.microphonePermission = .undetermined

        handler.start()
        handler.stop()
        system.answerSpeechAuthorization(.authorized)

        XCTAssertTrue(system.microphonePermissionRequests.isEmpty)
        XCTAssertTrue(system.activations.isEmpty)
        XCTAssertFalse(handler.isRecording)
        XCTAssertEqual(handler.authorizationStatus, .authorized, "what the person allowed still shows")
    }

    func test_stop_whileTheMicrophoneIsAsked_ignoresTheAnswer() {
        system.microphonePermission = .undetermined

        handler.start()
        handler.stop()
        system.answerMicrophonePermission(true)

        XCTAssertTrue(system.activations.isEmpty, "the microphone stays off")
        XCTAssertFalse(handler.isRecording)
    }

    func test_stop_whileTheMicrophoneIsAsked_ignoresADenial() {
        system.microphonePermission = .undetermined

        handler.start()
        handler.stop()
        system.answerMicrophonePermission(false)

        XCTAssertNil(handler.lastError, "the person stopped it before")
    }

    func test_stop_whileTheAudioSessionActivates_doesNotRecordAndDeactivatesIt() {
        handler.start()
        XCTAssertEqual(system.activations.count, 1)

        handler.stop()
        XCTAssertEqual(system.deactivations, 1, "so other apps' audio plays again")
        system.finishActivation()

        XCTAssertFalse(handler.isRecording)
        XCTAssertNil(handler.lastError)
        XCTAssertEqual(system.deactivations, 1)
    }

    func test_start_afterAStopWhileTheMicrophoneWasAsked_goesOnWithItsOwnAnswer() {
        system.microphonePermission = .undetermined
        handler.start()
        handler.stop()

        handler.start()
        XCTAssertEqual(system.microphonePermissionRequests.count, 2)
        system.answerMicrophonePermission(true, at: 0)
        XCTAssertTrue(system.activations.isEmpty, "the answer to the start that was stopped")

        system.answerMicrophonePermission(true, at: 1)
        XCTAssertEqual(system.activations.count, 1)
    }

    func test_start_whenTheAudioSessionCannotActivate_saysWhyAndDeactivatesIt() {
        handler.start()
        system.finishActivation(.failure(ActivationError()))

        XCTAssertTrue(handler.lastError is ActivationError)
        XCTAssertFalse(handler.isRecording)
        XCTAssertEqual(system.deactivations, 1)
    }

    func test_release_whileTheAudioSessionActivates_deactivatesIt() async throws {
        var dictation: SpeechHandler? = SpeechHandler(system: system)
        dictation?.start()
        XCTAssertEqual(system.activations.count, 1)

        dictation = nil
        system.finishActivation()

        try await waitUntil { system.deactivations == 1 }
    }

    func test_stop_whenItIsNotDictating_doesNothing() {
        handler.stop()

        XCTAssertEqual(system.deactivations, 0)
        XCTAssertFalse(handler.isRecording)
        XCTAssertNil(handler.lastError)
    }
}
