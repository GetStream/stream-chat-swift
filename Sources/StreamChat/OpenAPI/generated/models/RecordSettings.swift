//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct RecordSettings: Codable, Hashable {
    public var audioOnly: Bool
    public var mode: String
    public var quality: String
    public var layout: LayoutSettings? = nil

    public init(audioOnly: Bool, mode: String, quality: String, layout: LayoutSettings? = nil) {
        self.audioOnly = audioOnly
        self.mode = mode
        self.quality = quality
        self.layout = layout
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audioOnly = "audio_only"
        case mode
        case quality
        case layout
    }
}