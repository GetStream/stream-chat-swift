//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAudioSettings: Codable, Hashable {
    public var speakerDefaultOn: Bool
    
    public var accessRequestEnabled: Bool
    
    public var defaultDevice: String
    
    public var micDefaultOn: Bool
    
    public var opusDtxEnabled: Bool
    
    public var redundantCodingEnabled: Bool
    
    public init(speakerDefaultOn: Bool, accessRequestEnabled: Bool, defaultDevice: String, micDefaultOn: Bool, opusDtxEnabled: Bool, redundantCodingEnabled: Bool) {
        self.speakerDefaultOn = speakerDefaultOn
        
        self.accessRequestEnabled = accessRequestEnabled
        
        self.defaultDevice = defaultDevice
        
        self.micDefaultOn = micDefaultOn
        
        self.opusDtxEnabled = opusDtxEnabled
        
        self.redundantCodingEnabled = redundantCodingEnabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case speakerDefaultOn = "speaker_default_on"
        
        case accessRequestEnabled = "access_request_enabled"
        
        case defaultDevice = "default_device"
        
        case micDefaultOn = "mic_default_on"
        
        case opusDtxEnabled = "opus_dtx_enabled"
        
        case redundantCodingEnabled = "redundant_coding_enabled"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(speakerDefaultOn, forKey: .speakerDefaultOn)
        
        try container.encode(accessRequestEnabled, forKey: .accessRequestEnabled)
        
        try container.encode(defaultDevice, forKey: .defaultDevice)
        
        try container.encode(micDefaultOn, forKey: .micDefaultOn)
        
        try container.encode(opusDtxEnabled, forKey: .opusDtxEnabled)
        
        try container.encode(redundantCodingEnabled, forKey: .redundantCodingEnabled)
    }
}
