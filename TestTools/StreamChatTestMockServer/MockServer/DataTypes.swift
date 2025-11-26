//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public enum AttachmentType: String {
    case image
    case video
    case file

    var attachment: String {
        return rawValue
    }
}

public enum ReactionType: String {
    case love
    case lol = "haha"
    case wow
    case sad
    case like

    var reaction: String {
        return rawValue
    }
}

public enum MessageDeliveryStatus: String {
    case read
    case pending
    case sent
    case failed
    
    var status: String {
        return rawValue
    }
}
