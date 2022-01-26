//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the video duration to textual representation.
public protocol VideoDurationFormatter {
    func format(_ time: TimeInterval) -> String?
}

/// The default video duration formatter.
open class DefaultVideoDurationFormatter: VideoDurationFormatter {
    public var dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    public init() {}

    open func format(_ time: TimeInterval) -> String? {
        dateComponentsFormatter.string(from: time)
    }
}
