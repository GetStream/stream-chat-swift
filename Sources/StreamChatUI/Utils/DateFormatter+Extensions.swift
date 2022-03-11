//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension DateFormatter {
    static func makeDefault() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }
    
    /// Formatter that is used to format date for scrolling overlay that should display
    /// day when message below was sent
    public static let messageListDateOverlay: DateFormatter = {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMMdd")
        df.locale = .autoupdatingCurrent
        return df
    }()
}
// Date Formatter for chat user list
public struct DTFormatter {
    public static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}

extension DateComponentsFormatter {
    static var minutes: DateComponentsFormatter = {
        let df = DateComponentsFormatter()
        df.allowedUnits = [.minute]
        df.unitsStyle = .full
        return df
    }()
    
    static let videoDuration: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
}

extension NumberFormatter {
    static let uploadingPercentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
}
