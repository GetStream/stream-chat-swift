//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public enum StreamRuntimeCheck {
    /// Enables assertions thrown by the Stream SDK.
    ///
    /// When set to false, a message will be logged on console, but the assertion will not be thrown.
    public static var assertionsEnabled = false

    /// For *internal use* only
    ///
    ///  Enables background mapping of DB models
    public static var _isBackgroundMappingEnabled = false

    /// Enable/Disable local filtering for Channel lists. When enabled,
    /// the `ChannelDTO` will include the filter's predicate (if available)
    /// in the fetchRequest.
    public static var isChannelLocalFilteringEnabled = true
}
