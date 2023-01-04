//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIScrollView {
    var isTrackingOrDecelerating: Bool {
        isTracking || isDecelerating
    }
}
