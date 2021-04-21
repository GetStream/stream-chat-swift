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
}
