//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import Speech

// What dictation asks of the system before it records: the person's permissions, a recognizer,
// and the audio session. Each answer can come long after it is asked for, such as while the
// person reads a permission prompt.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
protocol SpeechSystem {
    var speechAuthorization: SFSpeechRecognizerAuthorizationStatus { get }
    func requestSpeechAuthorization(_ completion: @escaping @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void)
    var microphonePermission: MicrophonePermission { get }
    func requestMicrophonePermission(_ completion: @escaping @Sendable (Bool) -> Void)
    // A recognizer for `locale`, or else for the device's language, while it is available.
    func recognizer(for locale: Locale) -> SFSpeechRecognizer?
    func activateAudioSession(_ completion: @escaping @Sendable (Result<Void, Error>) -> Void)
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

    func requestSpeechAuthorization(_ completion: @escaping @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization(completion)
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

    func requestMicrophonePermission(_ completion: @escaping @Sendable (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: completion)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(completion)
        }
    }

    func recognizer(for locale: Locale) -> SFSpeechRecognizer? {
        guard let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(), recognizer.isAvailable else {
            return nil
        }
        return recognizer
    }

    func activateAudioSession(_ completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        Self.audioSessionQueue.async {
            completion(Result { try Self.activate() })
        }
    }

    func deactivateAudioSession() {
        Self.audioSessionQueue.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private nonisolated static func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
}
