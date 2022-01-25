//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the message timestamp to textual representation.
public protocol MessageTimestampFormatter {
    func format(_ date: Date) -> String
}

/// The default message timestamp formatter.
open class DefaultMessageTimestampFormatter: MessageTimestampFormatter {
    public lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    public init() {}

    open func format(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
