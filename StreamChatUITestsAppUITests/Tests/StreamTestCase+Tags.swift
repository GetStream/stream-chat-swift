//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamTestCase {
    enum Tags: String {
        case coreFeatures = "Core Features"
        case slowMode = "Slow Mode"
        case offlineSupport = "Offline Support"
        case messageDeliveryStatus = "Message Delivery Status"
    }

    func addTags(_ tags: [Tags]) {
        addTagsToScenario(tags.map{ $0.rawValue })
    }
}
