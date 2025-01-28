//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    
    func test_ignoringCacheIfContextHasInsertedOrDeletedObjectsOfThatType() async throws {
        let database = DatabaseContainer(kind: .inMemory, chatClientConfig: .init(apiKeyString: .unique))
        let cid = ChannelId.unique
        try database.createCurrentUser(id: .unique, name: "")
        try database.createChannel(cid: cid, withMessages: true)
        try await database.write { session in
            // FetchCache caches the response
            guard let firstPreviewMessage = session.preview(for: cid) else { throw ClientError.Unknown("Preview message missing") }
            
            // Insert a new message what is newer than the current preview message
            let newMessagePayload = MessagePayload.dummy(createdAt: firstPreviewMessage.createdAt.bridgeDate.addingTimeInterval(1.0))
            try session.saveMessage(payload: newMessagePayload, for: cid, syncOwnReactions: false, cache: nil)
            
            guard let secondPreviewMessage = session.preview(for: cid) else { throw ClientError.Unknown("Preview message missing") }
            XCTAssertEqual(newMessagePayload.id, secondPreviewMessage.id)
            XCTAssertNotEqual(firstPreviewMessage.id, secondPreviewMessage.id)
        }
    }
    
    // MARK: - Test Data

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

class TestId: NSManagedObjectID, @unchecked Sendable {
    override func uriRepresentation() -> URL {
        URL(string: "file://a")!
    }
}
