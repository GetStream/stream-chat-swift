//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChatOption: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let shortTitle: String
    public var customData: [String: Any]?
    public var action: () -> Void

    public static func == (lhs: ChatOption, rhs: ChatOption) -> Bool {
        lhs.id == rhs.id
    }
    
    public init(
        id: String,
        title: String,
        description: String,
        icon: String,
        shortTitle: String,
        customData: [String: Any]? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.customData = customData
        self.action = action
        self.shortTitle = shortTitle
    }
}
