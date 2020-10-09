//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class DeviceDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_deviceListPayload_isStoredAndLoadedFromDB() throws {
        let dummyDevices = DeviceListPayload.dummy
        
        try database.writeSynchronously { (session) in
            // Save a current user to db for testing
            try session.saveCurrentUser(payload: self.dummyCurrentUser)
            
            // Save dummy devices
            try session.saveCurrentUserDevices(dummyDevices.devices)
        }
        
        // Get current user from DB
        let loadedCurrentUser: CurrentChatUser? = database.viewContext.currentUser()?.asModel()
        
        // Check if fields are correct
        XCTAssertEqual(loadedCurrentUser?.devices.count, 2)
        let sortedCurrentUserDevices = loadedCurrentUser?.devices.sorted(by: { $0.id > $1.id })
        let sortedDummyDevices = dummyDevices.devices.sorted(by: { $0.id > $1.id })
        XCTAssertEqual(sortedCurrentUserDevices?.first?.id, sortedDummyDevices.first?.id)
        XCTAssertEqual(sortedCurrentUserDevices?.first?.createdAt, sortedDummyDevices.first?.createdAt)
    }
}
