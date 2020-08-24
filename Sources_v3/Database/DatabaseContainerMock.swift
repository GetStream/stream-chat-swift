//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient
import XCTest

class DatabaseContainerMock: DatabaseContainer {
    @Atomic var init_kind: DatabaseContainer.Kind
    @Atomic var flush_called = false
    
    convenience init() {
        try! self.init(kind: .inMemory)
    }
    
    override init(kind: DatabaseContainer.Kind, modelName: String = "StreamChatModel", bundle: Bundle? = nil) throws {
        init_kind = kind
        try super.init(kind: kind, modelName: modelName, bundle: bundle)
    }
    
    override func removeAllData(force: Bool, completion: ((Error?) -> Void)? = nil) {
        flush_called = true
        super.removeAllData(force: force, completion: completion)
    }
}
