//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - Protocol

/// A protocol describing an object that can configure/interact with `AVAudioSession`
public protocol AudioSessionConfiguring {
    /// The required initialiser
    init()

    /// Calling this method should activate the provided `AVAudioSession` for recording.
    ///
    /// - Note: The activation of the `AVAudioSession` is performed asynchronously, so this method
    /// won't report activation failures. Prefer `activateRecordingSession(completion:)` to get
    /// informed about them.
    func activateRecordingSession() throws

    /// Calling this method should activate the provided `AVAudioSession` for recording and call the
    /// provided completion handler once the activation has been completed.
    /// - Parameter completion: The closure to call with the activation's error or `nil` if the
    /// activation completed successfully.
    func activateRecordingSession(completion: (@Sendable (Error?) -> Void)?) throws

    /// Calling this method should deactivate recording from the provided `AVAudioSession`.
    ///
    /// - Note: The deactivation of the `AVAudioSession` is performed asynchronously, so this method
    /// won't report deactivation failures. Prefer `deactivateRecordingSession(completion:)` to get
    /// informed about them.
    func deactivateRecordingSession() throws

    /// Calling this method should deactivate recording from the provided `AVAudioSession` and call
    /// the provided completion handler once the deactivation has been completed.
    /// - Parameter completion: The closure to call with the deactivation's error or `nil` if the
    /// deactivation completed successfully.
    func deactivateRecordingSession(completion: (@Sendable (Error?) -> Void)?) throws

    /// Calling this method should activate the provided `AVAudioSession` for playback.
    ///
    /// - Note: The activation of the `AVAudioSession` is performed asynchronously, so this method
    /// won't report activation failures. Prefer `activatePlaybackSession(completion:)` to get
    /// informed about them.
    func activatePlaybackSession() throws

    /// Calling this method should activate the provided `AVAudioSession` for playback and call the
    /// provided completion handler once the activation has been completed.
    /// - Parameter completion: The closure to call with the activation's error or `nil` if the
    /// activation completed successfully.
    func activatePlaybackSession(completion: (@Sendable (Error?) -> Void)?) throws

    /// Calling this method should deactivate playback from the provided `AVAudioSession`.
    ///
    /// - Note: The deactivation of the `AVAudioSession` is performed asynchronously, so this method
    /// won't report deactivation failures. Prefer `deactivatePlaybackSession(completion:)` to get
    /// informed about them.
    func deactivatePlaybackSession() throws

    /// Calling this method should deactivate playback from the provided `AVAudioSession` and call
    /// the provided completion handler once the deactivation has been completed.
    /// - Parameter completion: The closure to call with the deactivation's error or `nil` if the
    /// deactivation completed successfully.
    func deactivatePlaybackSession(completion: (@Sendable (Error?) -> Void)?) throws

    /// Calling this method should go through iOS to get or request permission to record and once provided
    /// with a result, call the completionHandler to continue the flow.
    /// - Parameter completionHandler: The completion handler that will be called to continue the flow.
    func requestRecordPermission(
        _ completionHandler: @escaping @Sendable (Bool) -> Void
    )
}

public extension AudioSessionConfiguring {
    func activateRecordingSession(completion: (@Sendable (Error?) -> Void)?) throws {
        try activateRecordingSession()
        completion?(nil)
    }

    func deactivateRecordingSession(completion: (@Sendable (Error?) -> Void)?) throws {
        try deactivateRecordingSession()
        completion?(nil)
    }

    func activatePlaybackSession(completion: (@Sendable (Error?) -> Void)?) throws {
        try activatePlaybackSession()
        completion?(nil)
    }

    func deactivatePlaybackSession(completion: (@Sendable (Error?) -> Void)?) throws {
        try deactivatePlaybackSession()
        completion?(nil)
    }
}

// MARK: - Implementation

#if os(macOS) && !targetEnvironment(macCatalyst)
/// An implementation where for macOS we don't have interactions with AVAudioSession as it's not available.
open class StreamAudioSessionConfigurator: AudioSessionConfiguring {
    public required init() {}

    public func activateRecordingSession() throws { /* No-op */ }

    public func activateRecordingSession(completion: (@Sendable (Error?) -> Void)?) throws { completion?(nil) }

    public func deactivateRecordingSession() throws { /* No-op */ }

    public func deactivateRecordingSession(completion: (@Sendable (Error?) -> Void)?) throws { completion?(nil) }

    public func activatePlaybackSession() throws { /* No-op */ }

    public func activatePlaybackSession(completion: (@Sendable (Error?) -> Void)?) throws { completion?(nil) }

    public func deactivatePlaybackSession() throws { /* No-op */ }

    public func deactivatePlaybackSession(completion: (@Sendable (Error?) -> Void)?) throws { completion?(nil) }

    public func requestRecordPermission(_ completionHandler: @escaping @Sendable (Bool) -> Void) { completionHandler(true) }
}
#else
open class StreamAudioSessionConfigurator: AudioSessionConfiguring, @unchecked Sendable {
    // Activating or deactivating an `AVAudioSession` is a synchronous inter-process call which blocks
    // the caller long enough to make the UI unresponsive, so it's never performed on the caller's
    // thread. The queue is shared by every configurator, to ensure that activations and deactivations
    // are applied in the order they were requested.
    private static let sessionQueue = DispatchQueue(
        label: "io.getstream.audio-session",
        qos: .userInitiated
    )

    /// The audioSession with which the configurator will interact.
    private let audioSession: AudioSessionProtocol

    init(
        _ audioSession: AudioSessionProtocol
    ) {
        self.audioSession = audioSession
    }

    // MARK: - AudioSessionConfigurator

    public required init() {
        audioSession = AVAudioSession.sharedInstance()
    }

    /// Calling this method should activate the provided `AVAudioSession` for recording and playback.
    ///
    /// - Note: This method is using the `.playAndRecord` category with the `.spokenAudio` mode.
    /// - Note: The activation of the `AVAudioSession` is performed asynchronously, so this method
    /// won't report activation failures. Prefer `activateRecordingSession(completion:)` to get
    /// informed about them.
    open func activateRecordingSession() throws {
        try activateRecordingSession(completion: nil)
    }

    /// Calling this method should activate the provided `AVAudioSession` for recording and playback
    /// and call the provided completion handler once the activation has been completed.
    ///
    /// - Parameter completion: The closure to call with the activation's error or `nil` if the
    /// activation completed successfully.
    /// - Note: This method is using the `.playAndRecord` category with the `.spokenAudio` mode.
    open func activateRecordingSession(completion: (@Sendable (Error?) -> Void)?) throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            policy: .default,
            options: [
                .allowBluetoothDevice
            ]
        )
        setSessionActive(true, completion: completion)
    }

    /// Calling this method should deactivate the provided `AVAudioSession`.
    ///
    /// - Note: The deactivation of the `AVAudioSession` is performed asynchronously, so this method
    /// won't report deactivation failures. Prefer `deactivateRecordingSession(completion:)` to get
    /// informed about them.
    open func deactivateRecordingSession() throws {
        try deactivateRecordingSession(completion: nil)
    }

    /// Calling this method should deactivate the provided `AVAudioSession` and call the provided
    /// completion handler once the deactivation has been completed.
    ///
    /// - Parameter completion: The closure to call with the deactivation's error or `nil` if the
    /// deactivation completed successfully.
    open func deactivateRecordingSession(completion: (@Sendable (Error?) -> Void)?) throws {
        setSessionActive(false, completion: completion)
    }

    /// Calling this method should activate the provided `AVAudioSession` for playback and record.
    ///
    /// - Note: This method uses the `.playAndRecord` category with `.default` mode and policy.
    /// - Note: The activation of the `AVAudioSession` is performed asynchronously, so this method
    /// won't report activation failures. Prefer `activatePlaybackSession(completion:)` to get
    /// informed about them.
    open func activatePlaybackSession() throws {
        try activatePlaybackSession(completion: nil)
    }

    /// Calling this method should activate the provided `AVAudioSession` for playback and record and
    /// call the provided completion handler once the activation has been completed.
    ///
    /// - Parameter completion: The closure to call with the activation's error or `nil` if the
    /// activation completed successfully.
    /// - Note: This method uses the `.playAndRecord` category with `.default` mode and policy.
    open func activatePlaybackSession(completion: (@Sendable (Error?) -> Void)?) throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            policy: .default,
            options: [
                .defaultToSpeaker,
                .allowBluetoothDevice
            ]
        )
        setSessionActive(true, completion: completion)
    }

    /// Calling this method should deactivate the provided `AVAudioSession`.
    ///
    /// - Note: The deactivation of the `AVAudioSession` is performed asynchronously, so this method
    /// won't report deactivation failures. Prefer `deactivatePlaybackSession(completion:)` to get
    /// informed about them.
    open func deactivatePlaybackSession() throws {
        try deactivatePlaybackSession(completion: nil)
    }

    /// Calling this method should deactivate the provided `AVAudioSession` and call the provided
    /// completion handler once the deactivation has been completed.
    ///
    /// - Parameter completion: The closure to call with the deactivation's error or `nil` if the
    /// deactivation completed successfully.
    open func deactivatePlaybackSession(completion: (@Sendable (Error?) -> Void)?) throws {
        setSessionActive(false, completion: completion)
    }

    /// Requests recording permission from the underline `AVAudioSession` and invokes the provided
    /// completionHandler whenever there is an available response.
    ///
    /// - Parameters:
    ///     - completionHandler: The closure to call on the the `AVAudioSession` request returns
    ///     with a response.
    ///     - Note: The closure's invocation will be dispatched on the MainThread.
    open func requestRecordPermission(
        _ completionHandler: @escaping @Sendable (Bool) -> Void
    ) {
        audioSession.requestRecordPermission { [weak self] in
            self?.handleRecordPermissionResponse($0, completionHandler: completionHandler)
        }
    }

    // MARK: - Helpers

    private func setSessionActive(
        _ isActive: Bool,
        completion: (@Sendable (Error?) -> Void)?
    ) {
        Self.sessionQueue.async { [self] in
            do {
                try audioSession.setActive(isActive, options: [])
                completion?(nil)
            } catch {
                if let completion {
                    completion(error)
                } else {
                    log.error(error, subsystems: .audioPlayback)
                }
            }
        }
    }

    private func handleRecordPermissionResponse(
        _ permissionGranted: Bool,
        completionHandler: @escaping @Sendable (Bool) -> Void
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
}
#endif

// MARK: - Errors

final class AudioSessionConfiguratorError: ClientError, @unchecked Sendable {
    /// An unknown error occurred
    static func noAvailableInputsFound(
        file: StaticString = #file,
        line: UInt = #line
    ) -> AudioSessionConfiguratorError {
        .init("No available audio inputs found.", file, line)
    }
}

// MARK: -

extension AVAudioSession.CategoryOptions {
    #if compiler(>=6.2)
    static let allowBluetoothDevice: AVAudioSession.CategoryOptions = .allowBluetoothHFP
    #else
    static let allowBluetoothDevice: AVAudioSession.CategoryOptions = .allowBluetooth
    #endif
}
