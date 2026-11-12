//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 15.0, macOS 12.0, *)
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
