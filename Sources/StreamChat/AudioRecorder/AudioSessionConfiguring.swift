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

    func activatePlaybackSession(
        mode: AVAudioSession.Mode,
        policy: AVAudioSession.RouteSharingPolicy
    ) throws

    func deactivatePlaybackSession() throws

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
        guard audioSession.category == .record || audioSession.category == .playAndRecord else {
            return
        }
//        try audioSession.setActive(false)
    }

    open func activatePlaybackSession(
        mode: AVAudioSession.Mode,
        policy: AVAudioSession.RouteSharingPolicy
    ) throws {
        guard audioSession.category != .playback && audioSession.category != .playback else {
            try audioSession.setActive(true)
            return
        }
        try audioSession.setCategory(.playback, mode: mode, policy: policy)
        try audioSession.setActive(true)
    }

    open func deactivatePlaybackSession() throws {
        guard audioSession.category == .playback || audioSession.category == .playback else {
            return
        }
        try audioSession.setActive(false)
    }

    open func requestRecordPermission(
        _ completionHandler: @escaping (Bool) -> Void
    ) {
        audioSession.requestRecordPermission { [weak self] in
            self?.handleRecordPermissionResponse($0, completionHandler: completionHandler)
        }
    }

    // MARK: - Helpers

    private func handleRecordPermissionResponse(
        _ permissionGranted: Bool,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleRecordPermissionResponse(
                    permissionGranted,
                    completionHandler: completionHandler
                )
            }
            return
        }

        if permissionGranted {
            log.debug("🎤 Request Permission: ✅", subsystems: .audioRecording)
        } else {
            log.warning("🎤 Request Permission: ❌", subsystems: .audioRecording)
        }

        completionHandler(permissionGranted)
    }

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
