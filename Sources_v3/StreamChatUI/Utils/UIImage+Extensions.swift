//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init?(named name: String, in bundle: Bundle) {
        self.init(named: name, in: bundle, compatibleWith: nil)
    }
}
