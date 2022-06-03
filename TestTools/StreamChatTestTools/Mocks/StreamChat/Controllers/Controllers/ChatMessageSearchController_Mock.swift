//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatMessageSearchController_Mock: ChatMessageSearchController {
    public static func mock() -> ChatMessageSearchController_Mock {
        .init(client: .mock())
    }
    
    public var messages_mock: LazyCachedMapCollection<ChatMessage>?
    override public var messages: LazyCachedMapCollection<ChatMessage> {
        messages_mock ?? super.messages
    }
    
    override public func loadNextMessages(limit: Int = 25, completion: ((Error?) -> Void)? = nil) {
        completion?(nil)
    }
    
    override public func search(query: MessageSearchQuery, completion: ((Error?) -> Void)? = nil) {
        completion?(nil)
    }
}
