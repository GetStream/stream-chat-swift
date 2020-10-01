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
    
    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique
        
        let payload: UserPayload<DefaultExtraData.User> = .init(
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
        
        try database.writeSynchronously { session in
            // Save the user
            let userDTO = try! session.saveUser(payload: payload)
            // Make the extra data JSON invalid
            userDTO.extraData = #"{"invalid": json}"# .data(using: .utf8)!
        }
        
        let loadedUser: ChatUser? = database.viewContext.user(id: userId)?.asModel()
        XCTAssertEqual(loadedUser?.extraData, .defaultValue)
    }
    
    func test_DTO_asModel() {
        let userId = UUID().uuidString
        
        let payload: UserPayload<NameAndImageExtraData> = .dummy(userId: userId)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveUser(payload: payload)
        }
        
        // Load the user from the db and check the fields are correct
        var loadedUserModel: _ChatUser<NameAndImageExtraData>? {
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
    
    func test_userWithUserListQuery_isSavedAndLoaded() {
        let query = UserListQuery(filter: .contains("name", "a"))
        
        // Create user
        let payload1 = dummyUser
        let id1 = payload1.id
        
        let payload2 = dummyUser
        
        // Save the channels to DB, but only user 1 is associated with the query
        try! database.writeSynchronously { session in
            try session.saveUser(payload: payload1, query: query)
            try session.saveUser(payload: payload2)
        }
        
        let fetchRequest = UserDTO.userListFetchRequest(query: query)
        var loadedUsers: [UserDTO] {
            try! database.viewContext.fetch(fetchRequest)
        }
        
        XCTAssertEqual(loadedUsers.count, 1)
        XCTAssertEqual(loadedUsers.first?.id, id1)
    }
    
    func test_userListQuery_withSorting() {
        // Create two user queries with different sortings.
        let filter = Filter.equal("some", to: String.unique)
        let queryWithCreatedAtSorting = UserListQuery(filter: filter, sort: [.init(key: .createdAt, isAscending: false)])
        let queryWithUpdatedAtSorting = UserListQuery(filter: filter, sort: [.init(key: .updatedAt, isAscending: false)])

        // Create dummy users payloads.
        let payload1 = dummyUser
        let payload2 = dummyUser
        let payload3 = dummyUser
        let payload4 = dummyUser

        // Get dates and sort.
        let createdDates = [payload1, payload2, payload3, payload4]
            .map(\.createdAt)
            .sorted(by: { $0 > $1 })
        
        let updatedDates = [payload1, payload2, payload3, payload4]
            .map(\.updatedAt)
            .sorted(by: { $0 > $1 })

        // Save the users to DB. It doesn't matter which query we use because the filter for both of them is the same.
        try! database.writeSynchronously { session in
            try session.saveUser(payload: payload1, query: queryWithCreatedAtSorting)
            try session.saveUser(payload: payload2, query: queryWithCreatedAtSorting)
            try session.saveUser(payload: payload3, query: queryWithCreatedAtSorting)
            try session.saveUser(payload: payload4, query: queryWithCreatedAtSorting)
        }

        // A fetch request with a createdAt sorting.
        let fetchRequestWithCreatedAtSorting = UserDTO.userListFetchRequest(query: queryWithCreatedAtSorting)
        // A fetch request with a updatedAt sorting.
        let fetchRequestWithUpdatedAtSorting = UserDTO.userListFetchRequest(query: queryWithUpdatedAtSorting)

        var usersWithCreatedAtSorting: [UserDTO] { try! database.viewContext.fetch(fetchRequestWithCreatedAtSorting) }
        var usersWithUpdatedAtSorting: [UserDTO] { try! database.viewContext.fetch(fetchRequestWithUpdatedAtSorting) }
        
        // Check the createdAt sorting.
        XCTAssertEqual(usersWithCreatedAtSorting.count, 4)
        XCTAssertEqual(usersWithCreatedAtSorting.map(\.userCreatedAt), createdDates)
        
        // Check the updatedAt sorting.
        XCTAssertEqual(usersWithUpdatedAtSorting.count, 4)
        XCTAssertEqual(usersWithUpdatedAtSorting.map(\.userUpdatedAt), updatedDates)
    }

    /// `UserListSortingKey` test for sort descriptor and encoded value.
    func test_channelListSortingKey() {
        var userListSortingKey = UserListSortingKey.createdAt
        XCTAssertEqual(encodedUserListSortingKey(userListSortingKey), "created_at")
        XCTAssertEqual(
            userListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "userCreatedAt", ascending: true)
        )
        
        userListSortingKey = .lastActiveAt
        XCTAssertEqual(encodedUserListSortingKey(userListSortingKey), "lastActiveAt")
        XCTAssertEqual(
            userListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "lastActivityAt", ascending: true)
        )
        
        userListSortingKey = .updatedAt
        XCTAssertEqual(encodedUserListSortingKey(userListSortingKey), "updated_at")
        XCTAssertEqual(
            userListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "userUpdatedAt", ascending: true)
        )
    }
    
    private func encodedUserListSortingKey(_ sortingKey: UserListSortingKey) -> String {
        if #available(iOS 13, *) {
            let encodedData = try! JSONEncoder.stream.encode(sortingKey)
            return String(data: encodedData, encoding: .utf8)!.trimmingCharacters(in: .init(charactersIn: "\""))
        
        } else {
            @available(iOS, deprecated: 12.0, message: "Remove this workaround when dropping iOS 12 support.")
            // Workaround for a bug https://bugs.swift.org/browse/SR-6163 fixed in iOS 13
            let data = try! JSONEncoder.stream.encode(["key": sortingKey])
            let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
            return json["key"] as! String
        }
    }
}
