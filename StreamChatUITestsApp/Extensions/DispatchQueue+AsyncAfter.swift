//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension DispatchQueue {
    func asyncAfter(_ delay: DispatchTimeInterval, block: @escaping () -> Void) {
        asyncAfter(deadline: DispatchTime.now() + delay, execute: block)
    }
}
