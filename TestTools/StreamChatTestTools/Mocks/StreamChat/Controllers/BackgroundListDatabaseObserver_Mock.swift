//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
import XCTest

final class BackgroundListDatabaseObserver_Mock<Item, DTO: NSManagedObject>: BackgroundListDatabaseObserver<Item, DTO> {
    var synchronizeError: Error?

    override func startObserving() throws {
        if let error = synchronizeError {
            throw error
        } else {
            try super.startObserving()
        }
    }

    var items_mock: LazyCachedMapCollection<Item>?
    override var items: LazyCachedMapCollection<Item> {
        items_mock ?? super.items
    }
}

extension BackgroundListDatabaseObserver {
    func startObservingAndWaitForInitialUpdate(on testCase: XCTestCase, file: StaticString = #file, line: UInt = #line) throws {
        let expectation = testCase.expectation(description: "List update")
        onDidChange = { _ in
            expectation.fulfill()
        }
        try startObserving()
        testCase.wait(for: [expectation], timeout: defaultTimeout)
    }
}
