//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChatClient_v3
import XCTest

class ChangeAggregator_Tests: XCTestCase {
    var fakeController: NSFetchedResultsController<NSFetchRequestResult>!
    var aggregator: ChangeAggregator<TestManagedObject, String>!
    
    override func setUp() {
        super.setUp()
        // This is just for the delegate calls, we don't use it anywhere
        fakeController = .init()
        
        // We don't have to provide real creator. Let's just simply use the value that gets in
        aggregator = ChangeAggregator(itemCreator: { $0.testId })
    }
    
    func test_addingItems() {
        // Set up aggregator callback
        var result: [Change<String>]?
        aggregator.onChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate two inserts
        let insertedObject1 = TestManagedObject()
        let insertedObject2 = TestManagedObject()
        
        aggregator.controller(fakeController,
                              didChange: insertedObject1,
                              at: nil,
                              for: .insert,
                              newIndexPath: [0, 0])
        
        aggregator.controller(fakeController,
                              didChange: insertedObject2,
                              at: nil,
                              for: .insert,
                              newIndexPath: [1, 0])
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [.insert(insertedObject1.testId, index: [0, 0]), .insert(insertedObject2.testId, index: [1, 0])])
    }
    
    func test_movingItems() {
        // Set up aggregator callback
        var result: [Change<String>]?
        aggregator.onChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate two moves
        let movedObject1 = TestManagedObject()
        let movedObject2 = TestManagedObject()
        
        aggregator.controller(fakeController,
                              didChange: movedObject1,
                              at: [5, 0],
                              for: .move,
                              newIndexPath: [0, 0])
        
        aggregator.controller(fakeController,
                              didChange: movedObject2,
                              at: [4, 0],
                              for: .move,
                              newIndexPath: [1, 0])
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        // Move should also produce "update" change
        XCTAssertEqual(result, [
            .move(movedObject1.testId, fromIndex: [5, 0], toIndex: [0, 0]),
            .update(movedObject1.testId, index: [0, 0]),
            .move(movedObject2.testId, fromIndex: [4, 0], toIndex: [1, 0]),
            .update(movedObject2.testId, index: [1, 0])
        ])
    }
    
    func test_updatingItems() {
        // Set up aggregator callback
        var result: [Change<String>]?
        aggregator.onChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate two updates
        let updatedObject1 = TestManagedObject()
        let updatedObject2 = TestManagedObject()
        
        aggregator.controller(fakeController,
                              didChange: updatedObject1,
                              at: [1, 0],
                              for: .update,
                              newIndexPath: nil)
        
        aggregator.controller(fakeController,
                              didChange: updatedObject2,
                              at: [4, 0],
                              for: .update,
                              newIndexPath: nil)
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [
            .update(updatedObject1.testId, index: [1, 0]),
            .update(updatedObject2.testId, index: [4, 0])
        ])
    }
    
    func test_removingItems() {
        // Set up aggregator callback
        var result: [Change<String>]?
        aggregator.onChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate two removes
        let removedObject1 = TestManagedObject()
        let removedObject2 = TestManagedObject()
        
        aggregator.controller(fakeController,
                              didChange: removedObject1,
                              at: [1, 0],
                              for: .delete,
                              newIndexPath: nil)
        
        aggregator.controller(fakeController,
                              didChange: removedObject2,
                              at: [4, 0],
                              for: .delete,
                              newIndexPath: nil)
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [
            .remove(removedObject1.testId, index: [1, 0]),
            .remove(removedObject2.testId, index: [4, 0])
        ])
    }
    
    func test_complexUpdate() {
        var result: [Change<String>]?
        aggregator.onChange = { result = $0 }
        
        // Simulate FRC starts updating
        aggregator.controllerWillChangeContent(fakeController)
        
        // Simulate multiple different changes
        let addedObject = TestManagedObject()
        let movedObject = TestManagedObject()
        let removedObject = TestManagedObject()
        let updatedObject = TestManagedObject()
        
        aggregator.controller(fakeController,
                              didChange: addedObject,
                              at: nil,
                              for: .insert,
                              newIndexPath: [1, 0])
        
        aggregator.controller(fakeController,
                              didChange: movedObject,
                              at: [4, 0],
                              for: .move,
                              newIndexPath: [0, 0])
        
        aggregator.controller(fakeController,
                              didChange: removedObject,
                              at: [4, 0],
                              for: .delete,
                              newIndexPath: nil)
        
        aggregator.controller(fakeController,
                              didChange: updatedObject,
                              at: [2, 0],
                              for: .update,
                              newIndexPath: nil)
        
        // Simulate FRC finishes updating
        aggregator.controllerDidChangeContent(fakeController)
        
        XCTAssertEqual(result, [
            .insert(addedObject.testId, index: [1, 0]),
            .move(movedObject.testId, fromIndex: [4, 0], toIndex: [0, 0]),
            .update(movedObject.testId, index: [0, 0]),
            .remove(removedObject.testId, index: [4, 0]),
            .update(updatedObject.testId, index: [2, 0])
        ])
    }
}

class TestManagedObject: NSManagedObject {
    let testId: String = .unique
}
