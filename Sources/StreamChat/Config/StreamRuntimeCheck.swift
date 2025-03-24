//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public enum StreamRuntimeCheck {
    /// Enables assertions thrown by the Stream SDK.
    ///
    /// When set to false, a message will be logged on console, but the assertion will not be thrown.
    public static var assertionsEnabled: Bool {
        get { queue.sync { _assertionsEnabled } }
        set { queue.async { _assertionsEnabled = newValue } }
    }

    nonisolated(unsafe) private static var _assertionsEnabled = false
    
    /// For *internal use* only
    ///
    ///  Established the maximum depth of relationships to fetch when performing a mapping
    ///
    ///  Eg.
    ///  Relationship:    Message --->  QuotedMessage --->    QuotedMessage   ---X---     NIL
    ///  Relationship:    Channel  --->      Message         --->     QuotedMessage  ---X---     NIL
    ///  Depth:                     0                         1                                     2                               3
    static var _backgroundMappingRelationshipsMaxDepth: Int {
        get { queue.sync { __backgroundMappingRelationshipsMaxDepth } }
        set { queue.async { __backgroundMappingRelationshipsMaxDepth = newValue } }
    }

    nonisolated(unsafe) private static var __backgroundMappingRelationshipsMaxDepth = 2

    /// For *internal use* only
    ///
    ///  Returns true if the maximum depth of relationships to fetch when performing a mapping is not yet met
    static func _canFetchRelationship(currentDepth: Int) -> Bool {
        currentDepth <= _backgroundMappingRelationshipsMaxDepth
    }
    
    /// For *internal use* only
    ///
    /// Core Data prefetches data used for creating immutable model objects (faulting is disabled).
    public static var _isDatabasePrefetchingEnabled: Bool {
        get { queue.sync { __isDatabasePrefetchingEnabled } }
        set { queue.async { __isDatabasePrefetchingEnabled = newValue } }
    }

    nonisolated(unsafe) private static var __isDatabasePrefetchingEnabled = false
    
    // MARK: -
    
    private static let queue = DispatchQueue(label: "io.getstream.stream-runtime-check", target: .global())
}
