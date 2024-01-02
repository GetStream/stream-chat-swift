//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - Protocol

/// A protocol describing an object that can configure/interact with `AVAudioSession`
public protocol AudioSessionConfiguring {
    /// The required initialiser
    init()

    /// Calling this method should activate the provided `AVAudioSession` for recording.
    func activateRecordingSession() throws

    /// Calling this method should deactivate recording from the provided `AVAudioSession`.
    func deactivateRecordingSession() throws

    /// Calling this method should activate the provided `AVAudioSession` for playback.
    func activatePlaybackSession() throws

    /// Calling this method should deactivate playback from the provided `AVAudioSession`.
    func deactivatePlaybackSession() throws

    /// Calling this method should go through iOS to get or request permission to record and once provided
    /// with a result, call the completionHandler to continue the flow.
    /// - Parameter completionHandler: The completion handler that will be called to continue the flow.
    func requestRecordPermission(
        _ completionHandler: @escaping (Bool) -> Void
    )
}

// MARK: - Implementation

#if os(macOS) && !targetEnvironment(macCatalyst)
/// An implementation where for macOS we don't have interactions with AVAudioSession as it's not available.
open class StreamAudioSessionConfigurator: AudioSessionConfiguring {
    public required init() {}

    public func activateRecordingSession() throws { /* No-op */ }

    public func deactivateRecordingSession() throws { /* No-op */ }

    public func activatePlaybackSession() throws { /* No-op */ }

    public func deactivatePlaybackSession() throws { /* No-op */ }

    public func requestRecordPermission(_ completionHandler: @escaping (Bool) -> Void) { completionHandler(true) }
}
#else
open class StreamAudioSessionConfigurator: AudioSessionConfiguring {
    /// The audioSession with which the configurator will interact.
    private let audioSession: AudioSessionProtocol

    init(
        _ audioSession: AudioSessionProtocol
    ) {
        self.audioSession = audioSession
    }

    // MARK: - AudioSessionConfigurator

    public required convenience init() {
        self.init(AVAudioSession.sharedInstance())
    }

    /// Calling this method should activate the provided `AVAudioSession` for recording and playback.
    ///
    /// - Note: This method is using the `.playAndRecord` category with the `.spokenAudio` mode.
    /// The preferredInput will be set to `.buildInMic` and overrideOutputAudioPort to `.speaker`.
    open func activateRecordingSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            policy: .default,
            options: []
        )
        try setUpPreferredInput(.builtInMic)
        try activateSession()
    }

    /// Calling this method should deactivate the provided `AVAudioSession`.
    ///
    /// - Note: The method will check if the audioSession's category contains the `record` capability
    /// and if it does it will deactivate it. Otherwise, no action will be performed.
    open func deactivateRecordingSession() throws {
        try deactivateSession()
    }

    /// Calling this method should activate the provided `AVAudioSession` for playback and record.
    ///
    /// - Note: The method will check if the audioSession's category contains the `playAndRecord` capability
    /// and if it doesn't it will activate it using the `.playbackAndRecord` category and `.default` for both mode
    /// and policy.  OverrideOutputAudioPort is set to `.speaker`. The `record` capability is required
    /// ensure that the output port can be set to `.speaker`.
    open func activatePlaybackSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            policy: .default,
            options: []
        )
        try activateSession()
    }

    /// Calling this method should deactivate the provided `AVAudioSession`.
    ///
    /// - Note: The method will check if the audioSession's category contains the `playback` capability
    /// and if it does it will deactivate it. Otherwise, no action will be performed.
    open func deactivatePlaybackSession() throws {
        try deactivateSession()
    }

    /// Requests recording permission from the underline `AVAudioSession` and invokes the provided
    /// completionHandler whenever there is an available response.
    ///
    /// - Parameters:
    ///     - completionHandler: The closure to call on the the `AVAudioSession` request returns
    ///     with a response.
    ///     - Note: The closure's invocation will be dispatched on the MainThread.
    open func requestRecordPermission(
        _ completionHandler: @escaping (Bool) -> Void
    ) {
        audioSession.requestRecordPermission { [weak self] in
            self?.handleRecordPermissionResponse($0, completionHandler: completionHandler)
        }
    }

    // MARK: - Helpers

    private func activateSession() throws {
        try audioSession.overrideOutputAudioPort(.speaker)
        try audioSession.setActive(true, options: [])
    }

    private func deactivateSession() throws {
        try audioSession.overrideOutputAudioPort(.none)
        try audioSession.setActive(false, options: [])
    }

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
            throw AudioSessionConfiguratorError.noAvailableInputsFound()
        }
        try audioSession.setPreferredInput(preferredInput)
    }
}
#endif

// MARK: - Errors

final class AudioSessionConfiguratorError: ClientError {
    /// An unknown error occurred
    static func noAvailableInputsFound(
        file: StaticString = #file,
        line: UInt = #line
    ) -> AudioSessionConfiguratorError {
        .init("No available audio inputs found.", file, line)
    }
}
