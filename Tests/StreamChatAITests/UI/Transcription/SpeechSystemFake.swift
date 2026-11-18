//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Speech
@testable import StreamChatAI

// Records what dictation asks of the system, and answers when the test says, like a person who
// takes their time with a permission prompt.
@MainActor
final class SpeechSystemFake: SpeechSystem {
    var speechAuthorization: SFSpeechRecognizerAuthorizationStatus = .authorized
    var microphonePermission: MicrophonePermission = .granted
    private(set) var speechAuthorizationRequests: [@Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void] = []
    private(set) var microphonePermissionRequests: [@Sendable (Bool) -> Void] = []
    private(set) var activations: [@Sendable (Result<Void, Error>) -> Void] = []
    private(set) var deactivations = 0

    nonisolated init() { /* Nothing to set up. */ }

    func requestSpeechAuthorization(_ completion: @escaping @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        speechAuthorizationRequests.append(completion)
    }

    func requestMicrophonePermission(_ completion: @escaping @Sendable (Bool) -> Void) {
        microphonePermissionRequests.append(completion)
    }

    func recognizer(for locale: Locale) -> SFSpeechRecognizer? {
        SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func activateAudioSession(_ completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
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
    func answerMicrophonePermission(_ granted: Bool, at index: Int? = nil) {
        microphonePermission = granted ? .granted : .denied
        microphonePermissionRequests[index ?? microphonePermissionRequests.count - 1](granted)
    }

    func finishActivation(_ result: Result<Void, Error> = .success(())) {
        activations.last?(result)
    }
}
