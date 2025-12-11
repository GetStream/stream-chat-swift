//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

#if !os(macOS) || targetEnvironment(macCatalyst)
/// A simple protocol that abstracts the usage of AVAudioSession
protocol AudioSessionProtocol {
    var category: AVAudioSession.Category { get }

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

    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws
}

extension AVAudioSession: AudioSessionProtocol {}
#endif // #if os(macOS) && !targetEnvironment(macCatalyst)
