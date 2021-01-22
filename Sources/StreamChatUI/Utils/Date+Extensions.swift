//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Date {
    func getFormattedDate(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
