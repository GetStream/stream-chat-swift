//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the message date separator used in the message list to textual representation.
/// This formatter is used to display the message date between each group of messages
/// and the top date overlay in the message list.
public protocol MessageDateSeparatorFormatter {
    func format(_ date: Date) -> String
}

/// The default message date separator formatter.
open class DefaultMessageDateSeparatorFormatter: MessageDateSeparatorFormatter {
    public lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMdd")
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()

    open func format(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
