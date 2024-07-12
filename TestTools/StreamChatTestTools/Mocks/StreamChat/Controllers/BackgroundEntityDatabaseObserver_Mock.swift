//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

final class BackgroundEntityDatabaseObserver_Mock<Item, DTO: NSManagedObject>: BackgroundEntityDatabaseObserver<Item, DTO> {
    var synchronizeError: Error?
    var startObservingCalled: Bool = false

    override func startObserving() throws {
        if let error = synchronizeError {
            throw error
        } else {
            startObservingCalled = true
            try super.startObserving()
        }
    }

    var item_mock: Item?
    override var item: Item? {
        item_mock ?? super.item
    }
}

extension BackgroundEntityDatabaseObserver {
    func startObservingAndWaitForInitialUpdate(on testCase: XCTestCase, file: StaticString = #file, line: UInt = #line) throws {
        let expectation = testCase.expectation(description: "Entity update")
        expectation.assertForOverFulfill = false
        onChange { _ in
            expectation.fulfill()
        }
        try startObserving()
        testCase.wait(for: [expectation], timeout: defaultTimeout)
    }
}
