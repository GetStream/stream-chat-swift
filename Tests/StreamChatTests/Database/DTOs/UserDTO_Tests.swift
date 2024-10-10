//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class UserDTO_Tests: XCTestCase {
    var database: DatabaseContainer_Spy!

    override func setUp() {
        super.setUp()
        database = DatabaseContainer_Spy()
    }

    override func tearDown() {
        AssertAsync.canBeReleased(&database)
        database = nil
        super.tearDown()
    }

    func test_userPayload_isStoredAndLoadedFromDB() throws {
        let userId = UUID().uuidString

        let payload: UserPayload = .dummy(userId: userId, language: "pt")

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try session.saveUser(payload: payload)
        }

        // Load the user from the db and check the fields are correct
        let loadedUserDTO = try XCTUnwrap(database.viewContext.user(id: userId))

        AssertAsync {
            Assert.willBeEqual(payload.id, loadedUserDTO.id)
            Assert.willBeEqual(payload.name, loadedUserDTO.name)
            Assert.willBeEqual(payload.imageURL, loadedUserDTO.imageURL)
            Assert.willBeEqual(payload.isOnline, loadedUserDTO.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedUserDTO.isBanned)
            Assert.willBeEqual(payload.role.rawValue, loadedUserDTO.userRoleRaw)
            Assert.willBeEqual(payload.createdAt, loadedUserDTO.userCreatedAt.bridgeDate)
            Assert.willBeEqual(payload.updatedAt, loadedUserDTO.userUpdatedAt.bridgeDate)
            Assert.willBeEqual(payload.lastActiveAt, loadedUserDTO.lastActivityAt?.bridgeDate)
            Assert.willBeEqual(payload.teams, loadedUserDTO.teams)
            Assert.willBeEqual(loadedUserDTO.language, "pt")
            Assert.willBeEqual(
                payload.extraData,
                try? JSONDecoder.default.decode([String: RawJSON].self, from: loadedUserDTO.extraData)
            )
        }
    }

    func test_defaultExtraDataIsUsed_whenExtraDataDecodingFails() throws {
        let userId: UserId = .unique

        let payload: UserPayload = .init(
            id: userId,
            name: .unique,
            imageURL: .unique(),
            role: .admin,
            createdAt: .unique,
            updatedAt: .unique,
            deactivatedAt: nil,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: true,
            teams: [],
            language: nil,
            extraData: [:]
        )

        try database.writeSynchronously { session in
            // Save the user
            let userDTO = try! session.saveUser(payload: payload)
            // Make the extra data JSON invalid
            userDTO.extraData = #"{"invalid": json}"#.data(using: .utf8)!
        }

        let loadedUser: ChatUser? = try? database.viewContext.user(id: userId)?.asModel()
        XCTAssertEqual(loadedUser?.extraData, [:])
    }

    func test_DTO_asModel() throws {
        let userId = UUID().uuidString

        let payload: UserPayload = .dummy(userId: userId, extraData: ["k": .string("v")], language: "pt")

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try session.saveUser(payload: payload)
        }

        // Load the user from the db and check the fields are correct
        let loadedUserModel: ChatUser = try XCTUnwrap(database.viewContext.user(id: userId)?.asModel())

        AssertAsync {
            Assert.willBeEqual(payload.id, loadedUserModel.id)
            Assert.willBeEqual(payload.name, loadedUserModel.name)
            Assert.willBeEqual(payload.imageURL, loadedUserModel.imageURL)
            Assert.willBeEqual(payload.isOnline, loadedUserModel.isOnline)
            Assert.willBeEqual(payload.isBanned, loadedUserModel.isBanned)
            Assert.willBeEqual(payload.role, loadedUserModel.userRole)
            Assert.willBeEqual(payload.createdAt, loadedUserModel.userCreatedAt)
            Assert.willBeEqual(payload.updatedAt, loadedUserModel.userUpdatedAt)
            Assert.willBeEqual(payload.lastActiveAt, loadedUserModel.lastActiveAt)
            Assert.willBeEqual(payload.teams.sorted(), loadedUserModel.teams.sorted())
            Assert.willBeEqual(payload.extraData, loadedUserModel.extraData)
            Assert.willBeEqual(payload.language, loadedUserModel.language!.languageCode)
        }
    }

    func test_DTO_asPayload() throws {
        let userId = UUID().uuidString

        let payload: UserPayload = .dummy(userId: userId, extraData: ["k": .string("v")])

        // Asynchronously save the payload to the db
        try database.writeSynchronously { session in
            try! session.saveUser(payload: payload)
        }

        // Load the user from the db and check the fields are correct
        let loadedUserPayload = database.viewContext.user(id: userId)?.asRequestBody()

        XCTAssertEqual(payload.id, loadedUserPayload?.id)
        XCTAssertEqual(payload.extraData, loadedUserPayload?.extraData)
    }

    func test_DTO_resetsItsEphemeralValues() throws {
        // Create a new user and set it's online status to `true`
        let userId: UserId = .unique
        try database.writeSynchronously {
            let dto = try $0.saveUser(payload: UserPayload.dummy(userId: userId))
            dto.isOnline = true
        }

        // Reset ephemeral values
        database.resetEphemeralValues()

        // Check the online status is `false`
        XCTAssertEqual(database.viewContext.user(id: userId)?.isOnline, false)
    }

    func test_DTO_updateFromSamePayload_doNotProduceChanges() throws {
        // Arrange: Store random user payload to db
        let userId = UUID().uuidString
        let payload: UserPayload = .dummy(userId: userId)
        try database.writeSynchronously { session in
            try session.saveUser(payload: payload)
        }

        // Act: Save payload again
        let user = try database.viewContext.saveUser(payload: payload)

        // Assert: DTO should not contain any changes
        XCTAssertFalse(user.hasPersistentChangedValues)
    }

    func test_userWithUserListQuery_isSavedAndLoaded() {
        let query = UserListQuery(filter: .query(.name, text: "a"))

        // Create user
        let payload1 = dummyUser
        let id1 = payload1.id

        let payload2 = dummyUser

        // Save the channels to DB, but only user 1 is associated with the query
        try! database.writeSynchronously { session in
            try session.saveUser(payload: payload1, query: query, cache: nil)
            try session.saveUser(payload: payload2)
        }

        let fetchRequest = UserDTO.userListFetchRequest(query: query)
        var loadedUsers: [UserDTO] {
            try! database.viewContext.fetch(fetchRequest)
        }

        XCTAssertEqual(loadedUsers.count, 1)
        XCTAssertEqual(loadedUsers.first?.id, id1)
    }

    func test_userListQueryWithoutFilter_matchesAllUsers() throws {
        let query = UserListQuery()

        // Save 4 users to the DB
        try database.writeSynchronously { session in
            try session.saveUser(payload: self.dummyUser(id: .unique))
            try session.saveUser(payload: self.dummyUser(id: .unique))
            try session.saveUser(payload: self.dummyUser(id: .unique))
            try session.saveUser(payload: self.dummyUser(id: .unique))
        }

        let fetchRequest = UserDTO.userListFetchRequest(query: query)
        var loadedUsers: [UserDTO] {
            try! database.viewContext.fetch(fetchRequest)
        }

        XCTAssertEqual(loadedUsers.count, 4)
    }

    func test_userListQuery_withSorting() {
        // Create two user queries with different sortings.
        let filter = Filter<UserListFilterScope>.query(.name, text: "a")
        let queryWithLastActiveAtSorting = UserListQuery(filter: filter, sort: [.init(key: .lastActivityAt, isAscending: false)])
        let queryWithIdSorting = UserListQuery(filter: filter, sort: [.init(key: .id, isAscending: false)])

        // Create dummy users payloads.
        let payload1 = dummyUser
        let payload2 = dummyUser
        let payload3 = dummyUser
        let payload4 = dummyUser

        // Get parameters and sort.
        let lastActiveDates = [payload1, payload2, payload3, payload4]
            .compactMap(\.lastActiveAt)
            .sorted(by: { $0 > $1 })

        let ids = [payload1, payload2, payload3, payload4]
            .map(\.id)
            .sorted(by: { $0 > $1 })

        // Save the users to DB. It doesn't matter which query we use because the filter for both of them is the same.
        try! database.writeSynchronously { session in
            try session.saveUser(payload: payload1, query: queryWithLastActiveAtSorting, cache: nil)
            try session.saveUser(payload: payload2, query: queryWithLastActiveAtSorting, cache: nil)
            try session.saveUser(payload: payload3, query: queryWithLastActiveAtSorting, cache: nil)
            try session.saveUser(payload: payload4, query: queryWithLastActiveAtSorting, cache: nil)
        }

        // A fetch request with lastActiveAt sorting.
        let fetchRequestWithLastActiveAtSorting = UserDTO.userListFetchRequest(query: queryWithLastActiveAtSorting)
        // A fetch request with a id sorting.
        let fetchRequestWithIdSorting = UserDTO.userListFetchRequest(query: queryWithIdSorting)

        var usersWithLastActiveAtSorting: [UserDTO] { try! database.viewContext.fetch(fetchRequestWithLastActiveAtSorting) }
        var usersWithIdSorting: [UserDTO] { try! database.viewContext.fetch(fetchRequestWithIdSorting) }

        // Check the lastActiveAt sorting.
        XCTAssertEqual(usersWithLastActiveAtSorting.count, 4)
        XCTAssertEqual(usersWithLastActiveAtSorting.map(\.lastActivityAt?.bridgeDate), lastActiveDates)

        // Check the id sorting.
        XCTAssertEqual(usersWithIdSorting.count, 4)
        XCTAssertEqual(usersWithIdSorting.map(\.id), ids)
    }

    /// `UserListSortingKey` test for sort descriptor and encoded value.
    func test_userListSortingKey() {
        let encoder = JSONEncoder.stream
        var userListSortingKey = UserListSortingKey.id
        XCTAssertEqual(encoder.encodedString(userListSortingKey), "id")
        XCTAssertEqual(
            userListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "id", ascending: true)
        )

        userListSortingKey = .lastActivityAt
        XCTAssertEqual(encoder.encodedString(userListSortingKey), "last_active")
        XCTAssertEqual(
            userListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "lastActivityAt", ascending: true)
        )

        userListSortingKey = .isBanned
        XCTAssertEqual(encoder.encodedString(userListSortingKey), "banned")
        XCTAssertEqual(
            userListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "isBanned", ascending: true)
        )

        userListSortingKey = .role
        XCTAssertEqual(encoder.encodedString(userListSortingKey), "role")
        XCTAssertEqual(
            userListSortingKey.sortDescriptor(isAscending: true),
            NSSortDescriptor(key: "userRoleRaw", ascending: true)
        )
    }

    func test_userChange_triggerMembersUpdate() throws {
        // Arrange: Store member and user in database
        let userId: UserId = .unique
        let channelId: ChannelId = .unique

        let userPayload: UserPayload = .dummy(userId: userId)

        let payload: MemberPayload = .init(
            user: userPayload,
            userId: userPayload.id,
            role: .moderator,
            createdAt: .init(timeIntervalSince1970: 4000),
            updatedAt: .init(timeIntervalSince1970: 5000)
        )

        try database.writeSynchronously { session in
            try session.saveMember(payload: payload, channelId: channelId)
        }

        // Arrange: Observe changes on members
        let observer = StateLayerDatabaseObserver<EntityResult, MemberDTO, MemberDTO>(
            context: database.viewContext,
            fetchRequest: MemberDTO.member(userId, in: channelId)
        )
        var receivedChange: EntityChange<MemberDTO>?
        try observer.startObserving(onContextDidChange: { receivedChange = $1 })

        // Act: Update user
        try database.writeSynchronously { session in
            let loadedUser: UserDTO = try XCTUnwrap(session.user(id: userId))
            loadedUser.name = "Jo Jo"
        }

        // Assert: Members should be updated
        XCTAssertNotNil(receivedChange)
    }

    func test_userChange_triggerCurrentUserUpdate() throws {
        // Arrange: Store current user in database
        let userId: UserId = .unique

        let payload: CurrentUserPayload = .dummy(
            userId: userId,
            role: .admin,
            extraData: [:],
            devices: [DevicePayload.dummy],
            mutedUsers: [
                .dummy(userId: .unique)
            ]
        )

        try database.writeSynchronously { session in
            try session.saveCurrentUser(payload: payload)
        }

        // Arrange: Observe changes on current user
        let observer = StateLayerDatabaseObserver<EntityResult, CurrentUserDTO, CurrentUserDTO>(
            context: database.viewContext,
            fetchRequest: CurrentUserDTO.defaultFetchRequest
        )
        var receivedChange: EntityChange<CurrentUserDTO>?
        try observer.startObserving(onContextDidChange: { receivedChange = $1 })

        // Act: Update user
        try database.writeSynchronously { session in
            let loadedUser: UserDTO = try XCTUnwrap(session.user(id: userId))
            loadedUser.name = "Jo Jo"
        }

        // Assert: Members should be updated
        XCTAssertNotNil(receivedChange)
    }

    func test_userChange_triggerChannelUpdateForMembers() throws {
        // Arrange: Store messages in database
        let userId: UserId = .unique
        let channelId: ChannelId = .unique

        let memberPayload: MemberPayload = .dummy(user: .dummy(userId: userId))
        let channelPayload: ChannelPayload = .dummy(channel: .dummy(cid: channelId))
        let payload: MessagePayload = .dummy(
            showReplyInChannel: false,
            authorUserId: userId,
            text: "Yo"
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveMember(payload: memberPayload, channelId: channelId)
            try session.saveMessage(payload: payload, for: channelId, syncOwnReactions: false, cache: nil)
        }

        // Arrange: Observe changes on channel
        let observer = StateLayerDatabaseObserver<EntityResult, ChannelDTO, ChannelDTO>(
            context: database.viewContext,
            fetchRequest: ChannelDTO.fetchRequest(for: channelId)
        )
        var receivedChange: EntityChange<ChannelDTO>?
        try observer.startObserving(onContextDidChange: { receivedChange = $1 })
        
        // Act: Update user
        try database.writeSynchronously { session in
            let loadedUser: UserDTO = try XCTUnwrap(session.user(id: userId))
            loadedUser.name = "Jo Jo"
        }

        // Assert: Channel should be updated
        XCTAssertNotNil(receivedChange)
    }

    func test_userChange_whenNameOrImageUpdates_triggerMessagesUpdate() throws {
        // Arrange: Store messages in database
        let userId: UserId = .unique
        let channelId: ChannelId = .unique

        let userPayload: UserPayload = .dummy(userId: userId)
        let channelPayload: ChannelPayload = .dummy(channel: .dummy(cid: channelId))
        let payload: MessagePayload = .dummy(
            showReplyInChannel: false,
            authorUserId: userId,
            text: "Yo"
        )

        try database.writeSynchronously { session in
            try session.saveChannel(payload: channelPayload)
            try session.saveUser(payload: userPayload)
            try session.saveMessage(payload: payload, for: channelId, syncOwnReactions: false, cache: nil)
        }

        // Arrange: Observe changes on messages
        let observer = StateLayerDatabaseObserver<EntityResult, MessageDTO, MessageDTO>(
            context: database.viewContext,
            fetchRequest: MessageDTO.messagesFetchRequest(
                for: channelId,
                pageSize: 20,
                deletedMessagesVisibility: .alwaysVisible,
                shouldShowShadowedMessages: false
            )
        )
        var receivedChange: EntityChange<MessageDTO>?
        try observer.startObserving(onContextDidChange: { receivedChange = $1 })

        // Act: Update user name
        try database.writeSynchronously { session in
            let loadedUser: UserDTO = try XCTUnwrap(session.user(id: userId))
            loadedUser.name = "Jo Jo"
        }

        // Assert: Messages should be updated
        XCTAssertNotNil(receivedChange)

        // Reset
        receivedChange = nil

        // Act: Update user image
        try database.writeSynchronously { session in
            let loadedUser: UserDTO = try XCTUnwrap(session.user(id: userId))
            loadedUser.imageURL = .localYodaImage
        }

        // Assert: Messages should be updated
        XCTAssertNotNil(receivedChange)

        // Reset
        receivedChange = nil

        // Act: Update user lastActivityAt
        try database.writeSynchronously { session in
            let loadedUser: UserDTO = try XCTUnwrap(session.user(id: userId))
            loadedUser.lastActivityAt = .unique
        }

        // Assert: Messages should not update
        XCTAssertNil(receivedChange)
    }
}
