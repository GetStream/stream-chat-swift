//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the time a user was last active to textual representation.
public protocol UserLastActivityFormatter {
    func format(_ date: Date) -> String?
}

/// The default user last activity formatter.
open class DefaultUserLastActivityFormatter: UserLastActivityFormatter {
    public lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    open func format(_ date: Date) -> String? {
        DateUtils.timeAgo(relativeTo: date)
    }
}
