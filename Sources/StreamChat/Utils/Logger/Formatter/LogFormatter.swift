//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol LogFormatter {
    func format(logDetails: LogDetails, message: String) -> String
}
