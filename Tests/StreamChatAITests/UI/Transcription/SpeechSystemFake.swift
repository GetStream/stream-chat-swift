//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Speech
@testable import StreamChatAI
import XCTest

// Records what dictation asks of the system, and answers when the test says, like a person who
// takes their time with a permission prompt. Each answer is handled by the time it returns.
@MainActor
final class SpeechSystemFake: SpeechSystem {
    var speechAuthorization: SFSpeechRecognizerAuthorizationStatus = .authorized
    var microphonePermission: MicrophonePermission = .granted
    private(set) var speechAuthorizationRequests: [@MainActor @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void] = []
    private(set) var microphonePermissionRequests: [@MainActor @Sendable (Bool) -> Void] = []
    private(set) var activations: [@MainActor @Sendable (Result<Void, Error>) -> Void] = []
    private(set) var deactivations = 0

    nonisolated init() { /* Nothing to set up. */ }

    func requestSpeechAuthorization(_ completion: @escaping @MainActor @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        speechAuthorizationRequests.append(completion)
    }

    func requestMicrophonePermission(_ completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        microphonePermissionRequests.append(completion)
    }

    func recognizer(for locale: Locale) -> SFSpeechRecognizer? {
        SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func activateAudioSession(_ completion: @escaping @MainActor @Sendable (Result<Void, Error>) -> Void) {
        activations.append(completion)
    }

    func deactivateAudioSession() {
        deactivations += 1
    }

    // The person answers the latest speech recognition prompt.
    func answerSpeechAuthorization(_ status: SFSpeechRecognizerAuthorizationStatus) {
        speechAuthorization = status
        speechAuthorizationRequests.last?(status)
    }

    // The person answers the microphone prompt of the start at `index`, the latest by default.
    func answerMicrophonePermission(_ granted: Bool, at index: Int? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let index = index ?? microphonePermissionRequests.count - 1
        guard microphonePermissionRequests.indices.contains(index) else {
            XCTFail("No microphone prompt at \(index)", file: file, line: line)
            return
        }
        microphonePermission = granted ? .granted : .denied
        let answer = microphonePermissionRequests[index]
        answer(granted)
    }

    func finishActivation(_ result: Result<Void, Error> = .success(())) {
        activations.last?(result)
    }
}
