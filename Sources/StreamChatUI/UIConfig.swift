//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias UIConfig = _UIConfig<NoExtraData>

public struct _UIConfig<ExtraData: ExtraDataTypes> {
    public var channelList = ChannelListUI()
    public var messageList = MessageListUI()
    public var messageComposer = MessageComposer()
    public var currentUser = CurrentUserUI()
    public var navigation = Navigation()
    public var colorPalette = ColorPalette()
    public var font = Font()
    public var images = Images()

    public init() {}
}

// MARK: - UIConfig + Default

private var defaults: [String: Any] = [:]

public extension _UIConfig {
    static var `default`: Self {
        get {
            let key = String(describing: ExtraData.self)
            if let existing = defaults[key] as? Self {
                return existing
            } else {
                let config = Self()
                defaults[key] = config
                return config
            }
        }
        set {
            let key = String(describing: ExtraData.self)
            defaults[key] = newValue
        }
    }
}
