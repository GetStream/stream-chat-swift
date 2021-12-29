//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension DateFormatter {
    /// A formatter that converts the message timestamp to textual representation.
    public static var messageTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()
    
    /// A formatter that converts the message date to textual representation and used as a top overlay in the message list.
    public static var messageListDateOverlay: DateFormatter = {
        // By default it is the same as the messageListDateSeparator formatter.
        messageListDateSeparator
    }()

    /// A formatter that converts the message date to textual representation and used between each group of messages.
    public static var messageListDateSeparator: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMdd")
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
}

extension DateComponentsFormatter {
    /// A formatter that converts the minutes passed to textual representation.
    public static var minutes: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute]
        formatter.unitsStyle = .full
        return formatter
    }()

    /// A formatter that converts the video duration to textual representation.
    public static var videoDuration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
}

extension NumberFormatter {
    /// A formatter that converts the uploading percentage to textual representation.
    public static var uploadingPercentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
}
