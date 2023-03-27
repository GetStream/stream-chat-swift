//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - Protocol

public protocol AudioSessionConfiguring {
    static func build() -> AudioSessionConfiguring

    func activateRecordingSession(
        mode: AVAudioSession.Mode,
        policy: AVAudioSession.RouteSharingPolicy,
        preferredInput: AVAudioSession.Port
    ) throws

    func deactivateRecordingSession() throws

    func requestRecordPermission(
        _ completionHandler: @escaping (Bool) -> Void
    )
}

// MARK: - Errors

public struct StreamAudioSessionConfiguratorNoAvailableInputsFound: Error {}

// MARK: - Implementation

open class StreamAudioSessionConfigurator: AudioSessionConfiguring {
    private let audioSession: AVAudioSession

    public init(
        _ audioSession: AVAudioSession
    ) {
        self.audioSession = audioSession
    }

    // MARK: - AudioSessionConfigurator

    public static func build() -> AudioSessionConfiguring {
        StreamAudioSessionConfigurator(.sharedInstance())
    }

    open func activateRecordingSession(
        mode: AVAudioSession.Mode,
        policy: AVAudioSession.RouteSharingPolicy,
        preferredInput: AVAudioSession.Port
    ) throws {
        guard audioSession.category != .playAndRecord else {
            try audioSession.setActive(true)
            return
        }
        try audioSession.setCategory(.playAndRecord, mode: mode, policy: policy)
        try setUpPreferredInput(preferredInput)
        try audioSession.setActive(true)
    }

    open func deactivateRecordingSession() throws {
//        try audioSession.setActive(false)
    }

    open func requestRecordPermission(
        _ completionHandler: @escaping (Bool) -> Void
    ) {
        guard audioSession.recordPermission != .granted else {
            completionHandler(true)
            return
        }
        audioSession.requestRecordPermission { allowed in
            DispatchQueue.main.async {
                completionHandler(allowed)
            }
        }
    }

    // MARK: - Helpers

    private func setUpPreferredInput(
        _ preferredInput: AVAudioSession.Port
    ) throws {
        guard
            let availableInputs = audioSession.availableInputs,
            let preferredInput = availableInputs.first(where: { $0.portType == preferredInput })
        else {
            throw StreamAudioSessionConfiguratorNoAvailableInputsFound()
        }
        try audioSession.setPreferredInput(preferredInput)
    }
}
