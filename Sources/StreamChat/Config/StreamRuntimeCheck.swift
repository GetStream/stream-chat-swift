//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public extension StreamRuntimeCheck {
    /// For *internal use* only
    ///
    ///  Established the maximum depth of relationships to fetch when performing a mapping
    ///
    ///  Eg.
    ///  Relationship:    Message --->  QuotedMessage --->    QuotedMessage   ---X---     NIL
    ///  Relationship:    Channel  --->      Message         --->     QuotedMessage  ---X---     NIL
    ///  Depth:                     0                         1                                     2                               3
    nonisolated(unsafe) static var _backgroundMappingRelationshipsMaxDepth = 2

    /// For *internal use* only
    ///
    ///  Returns true if the maximum depth of relationships to fetch when performing a mapping is not yet met
    static func _canFetchRelationship(currentDepth: Int) -> Bool {
        currentDepth <= _backgroundMappingRelationshipsMaxDepth
    }
    
    /// For *internal use* only
    ///
    /// Core Data prefetches data used for creating immutable model objects (faulting is disabled).
    nonisolated(unsafe) static var _isDatabasePrefetchingEnabled = false
}
