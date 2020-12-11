//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension CALayer {
    func addShadow(color: UIColor) {
        masksToBounds = false
        shadowColor = color.cgColor
        shadowOffset = .zero
        shadowRadius = 8
        shadowOpacity = 0.85
    }
}
