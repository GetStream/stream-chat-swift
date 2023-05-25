//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// A simple protocol that abstracts the usage of AVAudioSession
protocol AudioSessionProtocol {
    var category: AVAudioSession.Category { get }
    var availableInputs: [AVAudioSessionPortDescription]? { get }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        policy: AVAudioSession.RouteSharingPolicy,
        options: AVAudioSession.CategoryOptions
    ) throws

    func setActive(
        _ active: Bool,
        options: AVAudioSession.SetActiveOptions
    ) throws

    func requestRecordPermission(_ response: @escaping (Bool) -> Void)

    func setPreferredInput(_ inPort: AVAudioSessionPortDescription?) throws

    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws
}

extension AVAudioSession: AudioSessionProtocol {}

extension AVAudioSession {
    /// Defining the method here as it's not available on macOS.
    @available(macOS 10.15, *)
    func setPreferredInput(_ inPort: AVAudioSessionPortDescription?) throws { /* No-op */ }
}
