//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension MessageReactionType {
    var position: Int {
        switch rawValue {
        case "love": return 0
        case "haha": return 1
        case "like": return 2
        case "sad": return 3
        case "wow": return 4
        default: return 5
        }
    }
}
