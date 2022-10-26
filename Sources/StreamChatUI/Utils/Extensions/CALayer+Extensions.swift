//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension CALayer {
    func addShadow(color: UIColor, radius: CGFloat = 8) {
        masksToBounds = false
        shadowColor = color.cgColor
        shadowOffset = .zero
        shadowRadius = radius
        
        // The shadow opacity must be 1 for now. Changing this value will make Intel vs M1 snapshots to not be the same.
        // So for now, we should try to fake transparency in the shadow color, for example, using a lighter color.
        shadowOpacity = 1.0
    }
}
