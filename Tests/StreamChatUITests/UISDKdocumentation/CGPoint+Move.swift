//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension CGPoint {
    mutating func move(x: CGFloat? = nil, y: CGFloat? = nil) {
        if let x = x {
            self.x += x
        }

        if let y = y {
            self.y += y
        }
    }
}
