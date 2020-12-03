//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension DispatchQueue {
    /// Returns one of the existing global Dispatch queues.
    static var random: DispatchQueue {
        let allQoS: [DispatchQoS.QoSClass] = [
            .userInteractive,
            .userInitiated,
            .default
        ]
        return DispatchQueue.global(qos: allQoS.randomElement()!)
    }
}
