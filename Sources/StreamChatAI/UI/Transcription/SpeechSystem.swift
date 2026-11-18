//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import Speech

// What dictation asks of the system before it records: the person's permissions, a recognizer,
// and the audio session. Each answer comes on the main actor, and can come long after it is
// asked for, such as while the person reads a permission prompt.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
protocol SpeechSystem: Sendable {
    var speechAuthorization: SFSpeechRecognizerAuthorizationStatus { get }
    func requestSpeechAuthorization(_ completion: @escaping @MainActor @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void)
    var microphonePermission: MicrophonePermission { get }
    func requestMicrophonePermission(_ completion: @escaping @MainActor @Sendable (Bool) -> Void)
    // A recognizer for `locale`, or else for the device's language, while it is available.
    func recognizer(for locale: Locale) -> SFSpeechRecognizer?
    func activateAudioSession(_ completion: @escaping @MainActor @Sendable (Result<Void, Error>) -> Void)
    func deactivateAudioSession()
}

@available(iOS 15.0, macOS 12.0, *)
enum MicrophonePermission {
    case undetermined
    case denied
    case granted
}

@available(iOS 15.0, macOS 12.0, *)
@MainActor
struct LiveSpeechSystem: SpeechSystem {
    // Activating and deactivating the audio session can block for a while, so both run here,
    // in order, off the main thread.
    private nonisolated static let audioSessionQueue = DispatchQueue(label: "io.getstream.ai.speech-audio-session")

    // So the handler's `init()`, which overrides `NSObject`'s, can make it.
    nonisolated init() { /* Nothing to set up. */ }

    var speechAuthorization: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    func requestSpeechAuthorization(_ completion: @escaping @MainActor @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization { @Sendable status in
            Task { @MainActor in completion(status) }
        }
    }

    var microphonePermission: MicrophonePermission {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined: return .undetermined
            case .granted: return .granted
            default: return .denied
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined: return .undetermined
            case .granted: return .granted
            default: return .denied
            }
        }
    }

    func requestMicrophonePermission(_ completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        let answer: @Sendable (Bool) -> Void = { granted in
            Task { @MainActor in completion(granted) }
        }
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: answer)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(answer)
        }
    }

    func recognizer(for locale: Locale) -> SFSpeechRecognizer? {
        guard let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(), recognizer.isAvailable else {
            return nil
        }
        return recognizer
    }

    func activateAudioSession(_ completion: @escaping @MainActor @Sendable (Result<Void, Error>) -> Void) {
        Self.audioSessionQueue.async {
            let activation = Result { try Self.activate() }
            Task { @MainActor in completion(activation) }
        }
    }

    func deactivateAudioSession() {
        Self.audioSessionQueue.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // `.record` silences other apps' audio while it is active, and takes no ducking, which is
    // for categories that play.
    private nonisolated static func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement)
        try session.setActive(true)
    }
}
