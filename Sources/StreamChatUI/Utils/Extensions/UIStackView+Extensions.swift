//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIStackView {
    func removeAllArrangedSubviews() {
        let subviews = arrangedSubviews
        subviews.forEach { self.removeArrangedSubview($0) }
    }
}
