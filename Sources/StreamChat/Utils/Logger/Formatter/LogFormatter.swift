//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol LogFormatter {
    func format(logDetails: LogDetails, message: String) -> String
}
