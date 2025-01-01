//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> Self {
        var result = self
        result.x += dx
        result.y += dy
        return result
    }
}
