//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIScrollView {
    /// Whether the user is scrolling or not. (Example: Will return false if the scroll view was scrolled programmatically)
    var isTrackingOrDecelerating: Bool {
        isTracking || isDecelerating
    }
}
