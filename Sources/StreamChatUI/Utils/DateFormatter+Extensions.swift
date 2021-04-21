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
}
