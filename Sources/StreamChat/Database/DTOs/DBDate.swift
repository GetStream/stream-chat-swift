//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

typealias DBDate = NSDate
extension DBDate {
    var bridgeDate: Date { self as Date }
}

extension Date {
    var bridgeDate: DBDate { self as DBDate }
}
