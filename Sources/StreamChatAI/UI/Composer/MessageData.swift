//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageData {
    public let text: String
    public let attachments: [URL]
    public var chatOption: ChatOption?
    
    public init(text: String, attachments: [URL] = [], chatOption: ChatOption? = nil) {
        self.text = text
        self.attachments = attachments
        self.chatOption = chatOption
    }
}
