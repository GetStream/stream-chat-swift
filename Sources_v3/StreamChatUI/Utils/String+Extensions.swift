//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
}
