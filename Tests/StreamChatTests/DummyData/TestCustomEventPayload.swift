//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

struct IdeaEventPayload: CustomEventPayload {
    static let eventType: EventType = "new_idea"
    
    let idea: String
}

extension IdeaEventPayload {
    static var unique: Self {
        .init(idea: .unique)
    }
}
