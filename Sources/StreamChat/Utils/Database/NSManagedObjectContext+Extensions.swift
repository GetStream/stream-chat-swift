//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    private static let localCachingKey = "io.getStream.StreamChat.local_caching_key"
    
    /// Provides the defaults for local caching and model serialization for this context.
    var localCachingSettings: ChatClientConfig.LocalCaching? {
        get { userInfo[Self.localCachingKey] as? ChatClientConfig.LocalCaching }
        set { userInfo[Self.localCachingKey] = newValue }
    }

    private static let deletedMessagesVisibilityKey = "io.getStream.StreamChat.deletedMessagesVisibility_key"
    
    private static let shouldShowShadowedMessagesKey = "io.getStream.StreamChat.shouldShowShadowedMessages_key"

    /// Provides the info about deleted messages behavior
    var deletedMessagesVisibility: ChatClientConfig.DeletedMessageVisibility? {
        get { userInfo[Self.deletedMessagesVisibilityKey] as? ChatClientConfig.DeletedMessageVisibility }
        set { userInfo[Self.deletedMessagesVisibilityKey] = newValue }
    }
    
    /// Provides the info about shadowed messages behavior
    var shouldShowShadowedMessages: Bool? {
        get { userInfo[Self.shouldShowShadowedMessagesKey] as? Bool }
        set { userInfo[Self.shouldShowShadowedMessagesKey] = newValue }
    }
}
