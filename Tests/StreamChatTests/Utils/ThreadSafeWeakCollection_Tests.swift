//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import XCTest

final class ThreadSafeWeakCollection_Tests: XCTestCase {
    func test_collection_isThreadSafe() {
        let collection = ThreadSafeWeakCollection<NSObject>()

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = collection.allObjects
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            collection.add(NSObject())
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            collection.removeAllObjects()
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = collection.count
        }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            _ = collection.contains(NSObject())
        }
    }
}
