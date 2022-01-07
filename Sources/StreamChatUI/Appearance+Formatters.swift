//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public extension Appearance {
    struct Formatters {
        /// A formatter that converts the message timestamp to textual representation.
        public var messageTimestamp: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            formatter.locale = Locale.autoupdatingCurrent
            return formatter
        }()

        /// A formatter that converts the message date separator to textual representation.
        public var messageListDateSeparator: DateFormatter = {
            let formatter = DateFormatter()
            formatter.setLocalizedDateFormatFromTemplate("MMMdd")
            formatter.locale = .autoupdatingCurrent
            return formatter
        }()

        /// A formatter that converts the minutes passed to textual representation.
        public var minutes: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.minute]
            formatter.unitsStyle = .full
            return formatter
        }()

        /// A formatter that converts the video duration to textual representation.
        public var videoDuration: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = .pad
            return formatter
        }()

        /// A formatter that converts the uploading percentage to textual representation.
        public var uploadingPercentage: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            return formatter
        }()
    }
}
