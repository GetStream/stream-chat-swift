//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public enum StreamRuntimeCheck {
    /// Enables assertions thrown by the Stream SDK.
    ///
    /// When set to false, a message will be logged on console, but the assertion will not be thrown.
    public static var assertionsEnabled = false
    
    /// For *internal use* only
    ///
    /// Enables reusing unchanged converted items in database observers.
    public static var _isDatabaseObserverItemReusingEnabled = true
}
