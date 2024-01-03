//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FetchCache_Tests: XCTestCase {
    func test_canBeAccessedFromMultipleThreads_sameRequest_sameInstance_shouldOnlyKeepOne() throws {
        let cache = FetchCache()
        let request = createRequest()

        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            let objectIDs = tenIds
            cache.set(request, objectIds: objectIDs)
        }

        XCTAssertEqual(cache.cacheEntriesCount, 1)
    }

    func test_fetchRequestWrapper_sameRequest_differentInstance_shouldOnlyKeepOne() {
        let cache = FetchCache()

        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            let objectIDs = tenIds
            let request = createRequest()

            XCTAssertTrue(!(request.entityName ?? "").isEmpty)

            cache.set(request, objectIds: objectIDs)
        }

        XCTAssertEqual(cache.cacheEntriesCount, 1)
    }

    func test_fetchRequestWrapper_sameRequest_differentSortDescriptorOrder_shouldHaveDifferentHashValue() {
        let cache = FetchCache()
        let objectIDs = tenIds
        let request = createRequest(sortDescriptors: [
            NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: false),
            NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: true)
        ])
        let request2 = createRequest(sortDescriptors: [
            NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: true),
            NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: false)
        ])
        let request3 = createRequest(sortDescriptors: [
            NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: true)
        ])

        cache.set(request, objectIds: objectIDs)
        cache.set(request2, objectIds: objectIDs)
        cache.set(request3, objectIds: objectIDs)

        XCTAssertEqual(cache.cacheEntriesCount, 3)
    }

    private var tenIds: [TestId] {
        (1...10).map { _ in TestId() }
    }

    private func createRequest(sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest<QueuedRequestDTO> {
        let request = NSFetchRequest<QueuedRequestDTO>(entityName: QueuedRequestDTO.entityName)
        request.sortDescriptors = sortDescriptors ?? [
            NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: false),
            NSSortDescriptor(keyPath: \QueuedRequestDTO.date, ascending: true)
        ]
        request.predicate = NSPredicate(format: "id == 1")
        request.fetchLimit = 3
        return request
    }
}

class TestId: NSManagedObjectID {
    override func uriRepresentation() -> URL {
        URL(string: "file://a")!
    }
}
