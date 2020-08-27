//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

class UserDTO_Tests: XCTestCase {
    var database: DatabaseContainerMock!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainerMock(kind: .inMemory)
    }
    
    func test_userPayload_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        
        let payload: UserPayload<NameAndImageExtraData> = .dummy(userId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedUserDTO: UserDTO? {
            database.viewContext.user(id: userId)
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedUserDTO?.id)
            Assert.willBeEqual(payload.isOnline, loadedUserDTO?.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedUserDTO?.isBanned)
            Assert.willBeEqual(payload.role.rawValue, loadedUserDTO?.userRoleRaw)
            Assert.willBeEqual(payload.createdAt, loadedUserDTO?.userCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedUserDTO?.userUpdatedAt)
            Assert.willBeEqual(payload.lastActiveAt, loadedUserDTO?.lastActivityAt)
            Assert.willBeEqual(payload.extraData, loadedUserDTO.map {
                try? JSONDecoder.default.decode(NameAndImageExtraData.self, from: $0.extraData)
            })
        }
    }
    
    func test_userPayload_withNoExtraData_isStoredAndLoadedFromDB() {
        let userId = UUID().uuidString
        
        let payload: UserPayload<NoExtraData> = .init(
            id: userId,
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            extraData: .defaultValue
        )
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedUserDTO: UserDTO? {
            database.viewContext.user(id: userId)
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedUserDTO?.id)
            Assert.willBeEqual(payload.isOnline, loadedUserDTO?.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedUserDTO?.isBanned)
            Assert.willBeEqual(payload.role.rawValue, loadedUserDTO?.userRoleRaw)
            Assert.willBeEqual(payload.createdAt, loadedUserDTO?.userCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedUserDTO?.userUpdatedAt)
            Assert.willBeEqual(payload.lastActiveAt, loadedUserDTO?.lastActivityAt)
            Assert.willBeEqual(payload.extraData, loadedUserDTO.map {
                try? JSONDecoder.default.decode(NoExtraData.self, from: $0.extraData)
            })
        }
    }
    
    func test_DTO_asModel() {
        let userId = UUID().uuidString
        
        let payload: UserPayload<NameAndImageExtraData> = .dummy(userId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedUserModel: UserModel<NameAndImageExtraData>? {
            database.viewContext.user(id: userId)?.asModel()
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedUserModel?.id)
            Assert.willBeEqual(payload.isOnline, loadedUserModel?.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedUserModel?.isBanned)
            Assert.willBeEqual(payload.role, loadedUserModel?.userRole)
            Assert.willBeEqual(payload.createdAt, loadedUserModel?.userCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedUserModel?.userUpdatedAt)
            Assert.willBeEqual(payload.lastActiveAt, loadedUserModel?.lastActiveAt)
            Assert.willBeEqual(payload.teams, loadedUserModel?.teams)
            Assert.willBeEqual(payload.extraData, loadedUserModel?.extraData)
        }
    }
    
    func test_DTO_asPayload() {
        let userId = UUID().uuidString
        
        let payload: UserPayload<NameAndImageExtraData> = .dummy(userId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedUserPayload: UserRequestBody<NameAndImageExtraData>? {
            database.viewContext.user(id: userId)?.asRequestBody()
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.id, loadedUserPayload?.id)
            Assert.willBeEqual(payload.extraData, loadedUserPayload?.extraData)
        }
    }
    
    func test_DTO_resetsItsEmpemeralValues() throws {
        // Create a new user and set it's online status to `true`
        let userId: UserId = .unique
        try database.writeSynchronously {
            let dto = try $0.saveUser(payload: UserPayload.dummy(userId: userId))
            dto.isOnline = true
        }
        
        // Reset ephemeral values
        try database.writeSynchronously {
            $0.user(id: userId)?.resetEphemeralValues()
        }
        
        // Check the online status is `false`
        XCTAssertEqual(database.viewContext.user(id: userId)?.isOnline, false)
    }
}
