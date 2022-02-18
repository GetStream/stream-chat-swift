//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

class QueuedRequestDTO_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()
        database = DatabaseContainerMock()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        super.tearDown()
    }

    func test_queuedRequestIsStoredInDatabase() throws {
        let id = String.newUniqueId
        let date = Date()
        let endpoint = Endpoint<EmptyResponse>(
            path: .guest,
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            requiresToken: false,
            body: ["something": 123]
        )
        let endpointData: Data = try JSONEncoder.stream.encode(endpoint)
        try database.writeSynchronously { _ in
            QueuedRequestDTO.createRequest(id: id, date: date, endpoint: endpointData, context: self.database.writableContext)
        }

        let allRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(allRequests.count, 1)
        let request = allRequests.first
        XCTAssertEqual(request?.id, id)
        XCTAssertEqual(request?.date, date)
        let databaseEndpointData = try XCTUnwrap(request?.endpoint)
        XCTAssertEqual(databaseEndpointData, endpointData)
        let databaseEndpoint = try JSONDecoder.stream.decode(Endpoint<EmptyResponse>.self, from: databaseEndpointData)
        XCTAssertEqual(databaseEndpoint.path.value, "guest")
        XCTAssertEqual(databaseEndpoint.method, .post)
        XCTAssertNil(databaseEndpoint.queryItems)
        XCTAssertTrue(databaseEndpoint.requiresConnectionId)
        XCTAssertFalse(databaseEndpoint.requiresToken)
        let databaseEndpointBodyData = try XCTUnwrap(databaseEndpoint.body as? Data)
        try XCTAssertEqual(
            JSONDecoder.stream.decode([String: Int].self, from: databaseEndpointBodyData),
            ["something": 123]
        )
    }

    func test_loadAllPendingRequestsReturnsAllStoredRequests() throws {
        let count = 5
        try createRequests(count: count)

        let allRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(allRequests.count, count)
        (1...count).forEach { id in
            XCTAssertTrue(allRequests.contains(where: { $0.id == "request\(id)" }))
        }
    }

    func test_loadIdReturnsDesiredRequest() throws {
        try createRequests(count: 5)

        let request = QueuedRequestDTO.load(id: "request2", context: database.viewContext)
        XCTAssertEqual(request?.id, "request2")
    }

    func test_deleteQueuedRequest() throws {
        try createRequests(count: 5)

        try database.writeSynchronously { session in
            session.deleteQueuedRequest(id: "request3")
        }

        let allRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(allRequests.count, 4)
        let deletedRequest = QueuedRequestDTO.load(id: "request3", context: database.viewContext)
        XCTAssertNil(deletedRequest)
    }

    private func createRequests(count: Int) throws {
        func createRequest(index: Int) throws {
            let id = "request\(index)"
            let date = Date()
            let endpoint = Endpoint<EmptyResponse>(
                path: .sendMessage("\(index)"),
                method: .post,
                queryItems: nil,
                requiresConnectionId: true,
                requiresToken: false,
                body: ["something\(index)": 123]
            )
            let endpointData: Data = try JSONEncoder.stream.encode(endpoint)
            QueuedRequestDTO.createRequest(id: id, date: date, endpoint: endpointData, context: database.writableContext)
        }

        try database.writeSynchronously { _ in
            try (1...count).forEach {
                try createRequest(index: $0)
            }
        }

        let allRequests = QueuedRequestDTO.loadAllPendingRequests(context: database.viewContext)
        XCTAssertEqual(allRequests.count, count)
    }
}
