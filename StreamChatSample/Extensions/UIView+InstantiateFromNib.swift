//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    static func instantiateFromNib() -> Self? {
        func instanceFromNib<T: UIView>() -> T? {
            UINib(nibName: "\(self)", bundle: nil).instantiate(withOwner: nil, options: nil).first as? T
        }

        return instanceFromNib()
    }
}
