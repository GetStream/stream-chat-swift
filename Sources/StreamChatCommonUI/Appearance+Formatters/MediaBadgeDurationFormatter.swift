//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts a media duration to textual representation.
///
/// Provides two formatting styles:
/// - ``longFormat(_:)`` – used in the Gallery (e.g. "1:23").
/// - ``shortFormat(_:)`` – compact contextual duration used in composer attachment previews (e.g. "8s", "1m", "1h").
public protocol MediaBadgeDurationFormatter {
    /// Long format produces "m:ss" strings (e.g. "0:08", "1:23", "12:05").
    func longFormat(_ duration: TimeInterval) -> String
    /// Short format produces compact contextual strings (e.g. "8s", "10m", "2h").
    func shortFormat(_ duration: TimeInterval) -> String
}

/// Default implementation of ``MediaBadgeDurationFormatter``.
open class DefaultMediaBadgeDurationFormatter: MediaBadgeDurationFormatter {
    public init() {}

    open func longFormat(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    open func shortFormat(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        } else if totalSeconds < 3600 {
            return "\(totalSeconds / 60)m"
        } else {
            return "\(totalSeconds / 3600)h"
        }
    }
}
