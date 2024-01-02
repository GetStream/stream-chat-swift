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
    ///  Enables background mapping of DB models
    public static var _isBackgroundMappingEnabled = false

    /// For *internal use* only
    ///
    ///  Established the maximum depth of relationships to fetch when performing a mapping
    ///
    ///  Eg.
    ///  Relationship:    Message --->  QuotedMessage --->    QuotedMessage   ---X---     NIL
    ///  Relationship:    Channel  --->      Message         --->     QuotedMessage  ---X---     NIL
    ///  Depth:                     0                         1                                     2                               3
    static var _backgroundMappingRelationshipsMaxDepth = 2

    /// For *internal use* only
    ///
    ///  Returns true if the maximum depth of relationships to fetch when performing a mapping is not yet met
    static func _canFetchRelationship(currentDepth: Int) -> Bool {
        guard _isBackgroundMappingEnabled else { return true }

        return currentDepth <= _backgroundMappingRelationshipsMaxDepth
    }
}
