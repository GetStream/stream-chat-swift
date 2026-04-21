//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AudioSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var accessRequestEnabled: Bool
    var defaultDevice: String
    var hifiAudioEnabled: Bool
    var micDefaultOn: Bool
    var noiseCancellation: NoiseCancellationSettings?
    var opusDtxEnabled: Bool
    var redundantCodingEnabled: Bool
    var speakerDefaultOn: Bool

    init(accessRequestEnabled: Bool, defaultDevice: String, hifiAudioEnabled: Bool, micDefaultOn: Bool, noiseCancellation: NoiseCancellationSettings? = nil, opusDtxEnabled: Bool, redundantCodingEnabled: Bool, speakerDefaultOn: Bool) {
        self.accessRequestEnabled = accessRequestEnabled
        self.defaultDevice = defaultDevice
        self.hifiAudioEnabled = hifiAudioEnabled
        self.micDefaultOn = micDefaultOn
        self.noiseCancellation = noiseCancellation
        self.opusDtxEnabled = opusDtxEnabled
        self.redundantCodingEnabled = redundantCodingEnabled
        self.speakerDefaultOn = speakerDefaultOn
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case defaultDevice = "default_device"
        case hifiAudioEnabled = "hifi_audio_enabled"
        case micDefaultOn = "mic_default_on"
        case noiseCancellation = "noise_cancellation"
        case opusDtxEnabled = "opus_dtx_enabled"
        case redundantCodingEnabled = "redundant_coding_enabled"
        case speakerDefaultOn = "speaker_default_on"
    }

    static func == (lhs: AudioSettingsResponse, rhs: AudioSettingsResponse) -> Bool {
        lhs.accessRequestEnabled == rhs.accessRequestEnabled &&
            lhs.defaultDevice == rhs.defaultDevice &&
            lhs.hifiAudioEnabled == rhs.hifiAudioEnabled &&
            lhs.micDefaultOn == rhs.micDefaultOn &&
            lhs.noiseCancellation == rhs.noiseCancellation &&
            lhs.opusDtxEnabled == rhs.opusDtxEnabled &&
            lhs.redundantCodingEnabled == rhs.redundantCodingEnabled &&
            lhs.speakerDefaultOn == rhs.speakerDefaultOn
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(accessRequestEnabled)
        hasher.combine(defaultDevice)
        hasher.combine(hifiAudioEnabled)
        hasher.combine(micDefaultOn)
        hasher.combine(noiseCancellation)
        hasher.combine(opusDtxEnabled)
        hasher.combine(redundantCodingEnabled)
        hasher.combine(speakerDefaultOn)
    }
}
