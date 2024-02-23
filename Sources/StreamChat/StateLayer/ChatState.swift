//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public final class ChatState: ObservableObject {
    private let cid: ChannelId
    let messageOrder: MessageOrdering
    
    init(cid: ChannelId, messageOrder: MessageOrdering) {
        self.cid = cid
        self.messageOrder = messageOrder
    }
    
    // MARK: Messages
    
    @Published public private(set) var messages: [ChatMessage] = []
    
    @MainActor func setMessages(_ messages: [ChatMessage]) {
        self.messages = messages
    }
}
