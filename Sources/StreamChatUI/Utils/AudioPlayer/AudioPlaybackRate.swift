//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

// Defines an enumeration for audio playback rate with a raw value of Float
public enum AudioPlaybackRate: Float, CustomStringConvertible {
    case zero = 0
    case half = 0.5
    case normal = 1
    case double = 2

    public init?(rawValue: Float) {
        // Switch statement that maps the rawValue to a case of AudioPlaybackRate
        switch rawValue {
        case 0:
            self = .zero
        case 0.5:
            self = .half
        case 1:
            self = .normal
        case 2:
            self = .double
        default:
            self = .normal
        }
    }

    // Computed property that returns a string representation of the playback rate
    public var description: String {
        switch self {
        case .zero:
            return "x0"
        case .half:
            return "x0.5"
        case .normal:
            return "x1"
        case .double:
            return "x2"
        }
    }

    // Computed property that returns the next playback rate
    public var next: AudioPlaybackRate {
        switch self {
        case .zero:
            return .half
        case .half:
            return .normal
        case .normal:
            return .double
        case .double:
            return .half
        }
    }
}
