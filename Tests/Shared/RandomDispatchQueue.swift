//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension DispatchQueue {
    /// Returns one of the existing global Dispatch queues.
    static var random: DispatchQueue {
        let allQoS: [DispatchQoS.QoSClass] = [
            .userInteractive,
            .userInitiated,
            .default,
            .utility,
            .background
        ]
        return DispatchQueue.global(qos: allQoS.randomElement()!)
    }
}
