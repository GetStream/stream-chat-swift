//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreGraphics

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        let origin = CGPoint(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2
        )

        self.init(origin: origin, size: size)
    }

    var center: CGPoint {
        .init(
            x: origin.x + size.width / 2,
            y: origin.y + size.height / 2
        )
    }

    static func circleBounds(center: CGPoint, radius: CGFloat) -> Self {
        .init(
            center: center,
            size: .init(
                width: radius * 2,
                height: radius * 2
            )
        )
    }
}
