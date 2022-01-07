//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension OptionSet {
    /// Checks if the option set contains at least one of the provided options.
    func contains(oneOf members: [Element]) -> Bool {
        for member in members {
            if contains(member) {
                return true
            }
        }
        return false
    }
}
