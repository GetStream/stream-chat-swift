//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts a video duration to a short textual representation.
public protocol VideoDurationShortFormatter {
    func format(_ duration: TimeInterval) -> String?
}

/// The default short video duration formatter.
///
/// Uses `DateComponentsFormatter` with the `.abbreviated` units style
/// restricted to seconds only (e.g. "8s", "60s", "120s").
open class DefaultVideoDurationShortFormatter: VideoDurationShortFormatter {
    public var dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.second]
        return formatter
    }()

    public init() {}

    open func format(_ duration: TimeInterval) -> String? {
        dateComponentsFormatter.string(from: duration)
    }
}
