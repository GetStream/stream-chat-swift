//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIScrollView {
    var isTrackingOrDecelerating: Bool {
        isTracking || isDecelerating
    }
}
