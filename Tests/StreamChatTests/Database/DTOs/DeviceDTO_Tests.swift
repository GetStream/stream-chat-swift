//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class DeviceDTO_Tests: XCTestCase {
    var database: DatabaseContainer!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_deviceListPayload_isStoredAndLoadedFromDB() throws {
        let dummyDevices = ListDevicesResponse.dummy()

        try database.writeSynchronously { (session) in
            // Save a current user to db for testing
            try session.saveCurrentUser(payload: self.dummyCurrentUser)

            // Save dummy devices
            try session.saveCurrentUserDevices(dummyDevices.devices)
        }

        // Get current user from DB
        let loadedCurrentUser: CurrentChatUser? = try database.viewContext.currentUser?.asModel()

        // Check if fields are correct
        XCTAssertEqual(loadedCurrentUser?.devices.count, 2)
        let sortedCurrentUserDevices = loadedCurrentUser?.devices.sorted(by: { $0.id > $1.id })
        let sortedDummyDevices = dummyDevices.devices.sorted(by: { $0.id > $1.id })
        XCTAssertEqual(sortedCurrentUserDevices?.first?.id, sortedDummyDevices.first?.id)
        XCTAssertEqual(sortedCurrentUserDevices?.first?.createdAt, sortedDummyDevices.first?.createdAt)
    }

    func test_deviceAllFields_areStoredAndLoadedFromDB() throws {
        let device = Device(
            createdAt: .unique,
            disabled: true,
            disabledReason: "spam",
            hardwareId: "hw-1",
            id: .unique,
            pushProvider: "firebase",
            pushProviderName: "my-fcm",
            userId: .unique,
            voip: true
        )

        try database.writeSynchronously { (session) in
            try session.saveCurrentUser(payload: self.dummyCurrentUser)
            try session.saveCurrentUserDevices([device])
        }

        let loadedCurrentUser: CurrentChatUser? = try database.viewContext.currentUser?.asModel()
        let loadedDevice = loadedCurrentUser?.devices.first

        XCTAssertEqual(loadedDevice?.id, device.id)
        XCTAssertEqual(loadedDevice?.createdAt, device.createdAt)
        XCTAssertEqual(loadedDevice?.disabled, device.disabled)
        XCTAssertEqual(loadedDevice?.disabledReason, device.disabledReason)
        XCTAssertEqual(loadedDevice?.hardwareId, device.hardwareId)
        XCTAssertEqual(loadedDevice?.pushProvider, device.pushProvider)
        XCTAssertEqual(loadedDevice?.pushProviderName, device.pushProviderName)
        XCTAssertEqual(loadedDevice?.userId, device.userId)
        XCTAssertEqual(loadedDevice?.voip, device.voip)
    }
}
