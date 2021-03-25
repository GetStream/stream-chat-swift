//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    private static let channelConfigKey = "io.getStream.chat.core.channel_config_key"
    
    var channelConfig: ChatClientConfig.Channel? {
        get { userInfo[Self.channelConfigKey] as? ChatClientConfig.Channel }
        set { userInfo[Self.channelConfigKey] = newValue }
    }
}
