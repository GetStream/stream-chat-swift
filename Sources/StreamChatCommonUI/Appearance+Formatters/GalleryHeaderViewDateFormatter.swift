//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the message timestamp to textual representation for the gallery header view.
public protocol GalleryHeaderViewDateFormatter {
    func format(_ date: Date) -> String
}

/// The default gallery header view date formatter.
open class DefaultGalleryHeaderViewDateFormatter: GalleryHeaderViewDateFormatter {
    public var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    var calendar: StreamCalendar = Calendar.current

    public init() {}

    open func format(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return dayFormatter.string(from: date)
        }

        if calendar.isDateInYesterday(date) {
            return dayFormatter.string(from: date)
        }

        return dateFormatter.string(from: date)
    }
}
