//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension CALayer {
    func addShadow(color: UIColor) {
        masksToBounds = false
        shadowOffset = .zero
        shadowRadius = 8
        shadowColor = color.withAlphaComponent(0.85).cgColor
        shadowOpacity = 1
    }
}
