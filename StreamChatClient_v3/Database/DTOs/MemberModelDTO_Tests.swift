//
// MemberModelDTO_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class MemberModelDTO_Tests: XCTestCase {
    var database: DatabaseContainer!
    
    override func setUp() {
        super.setUp()
        database = try! DatabaseContainer(kind: .inMemory)
    }
    
    func test_memberPayload_isStoredAndLoadedFromDB() throws {
        let userId = UUID().uuidString
        let channelId = ChannelId(type: .init(rawValue: "messsaging"), id: UUID().uuidString)
        
        let userPayload: UserPayload<NameAndImageExtraData> = .init(id: userId,
                                                                    created: .init(timeIntervalSince1970: 1000),
                                                                    updated: .init(timeIntervalSince1970: 2000),
                                                                    lastActiveDate: .init(timeIntervalSince1970: 3000),
                                                                    isOnline: true,
                                                                    isInvisible: true,
                                                                    isBanned: true,
                                                                    roleRawValue: "admin",
                                                                    extraData: .init(name: "Luke",
                                                                                     imageURL: URL(string: UUID()
                                                                                         .uuidString)),
                                                                    devices: [],
                                                                    mutedUsers: [],
                                                                    unreadChannelsCount: nil,
                                                                    unreadMessagesCount: nil,
                                                                    teams: [])
        
        let payload: MemberPayload<NameAndImageExtraData> = .init(roleRawValue: "moderator",
                                                                  created: .init(timeIntervalSince1970: 4000),
                                                                  updated: .init(timeIntervalSince1970: 5000),
                                                                  user: userPayload)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveMember(payload: payload, channelId: channelId)
        }
        
        // Load the member from the db and check it's the same member
        var loadedMember: MemberModel<NameAndImageExtraData>? {
            database.viewContext.loadMember(id: userId, channelId: channelId)
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.user.id, loadedMember?.id)
            Assert.willBeEqual(payload.user.isOnline, loadedMember?.isOnline)
            Assert.willBeEqual(payload.user.isBanned, loadedMember?.isBanned)
            Assert.willBeEqual(payload.user.roleRawValue, loadedMember?.userRole.rawValue)
            Assert.willBeEqual(payload.user.created, loadedMember?.userCreatedDate)
            Assert.willBeEqual(payload.user.updated, loadedMember?.userUpdatedDate)
            Assert.willBeEqual(payload.user.lastActiveDate, loadedMember?.lastActiveDate)
            Assert.willBeEqual(payload.user.extraData, loadedMember?.extraData)
            Assert.willBeEqual(payload.roleRawValue, loadedMember?.channelRole.rawValue)
            Assert.willBeEqual(payload.created, loadedMember?.memberCreatedDate)
            Assert.willBeEqual(payload.updated, loadedMember?.memberUpdatedDate)
//      Assert.willBeEqual(payload.user.isInvited, loadedMember?.isInvited)
//      Assert.willBeEqual(payload.user.inviteAcceptedDate, loadedMember?.inviteAcceptedDate)
//      Assert.willBeEqual(payload.user.inviteRejectedDate, loadedMember?.inviteRejectedDate)
        }
    }
    
    func test_memberPayload_withNoExtraData_isStoredAndLoadedFromDB() throws {
        let userId = UUID().uuidString
        let channelId = ChannelId(type: .init(rawValue: "messsaging"), id: UUID().uuidString)
        
        let userPayload: UserPayload<NoExtraData> = .init(id: userId,
                                                          created: .init(timeIntervalSince1970: 1000),
                                                          updated: .init(timeIntervalSince1970: 2000),
                                                          lastActiveDate: .init(timeIntervalSince1970: 3000),
                                                          isOnline: true,
                                                          isInvisible: true,
                                                          isBanned: true,
                                                          roleRawValue: "admin",
                                                          extraData: .init(),
                                                          devices: [],
                                                          mutedUsers: [],
                                                          unreadChannelsCount: nil,
                                                          unreadMessagesCount: nil,
                                                          teams: [])
        
        let payload: MemberPayload<NoExtraData> = .init(roleRawValue: "moderator",
                                                        created: .init(timeIntervalSince1970: 4000),
                                                        updated: .init(timeIntervalSince1970: 5000),
                                                        user: userPayload)
        
        // Asynchronously save the payload to the db
        database.write { session in
            try! session.saveMember(payload: payload, channelId: channelId)
        }
        
        // Load the member from the db and check it's the same member
        var loadedMember: MemberModel<NameAndImageExtraData>? {
            database.viewContext.loadMember(id: userId, channelId: channelId)
        }
        
        AssertAsync {
            Assert.willBeEqual(payload.user.id, loadedMember?.id)
            Assert.willBeEqual(payload.user.isOnline, loadedMember?.isOnline)
            Assert.willBeEqual(payload.user.isBanned, loadedMember?.isBanned)
            Assert.willBeEqual(payload.user.roleRawValue, loadedMember?.userRole.rawValue)
            Assert.willBeEqual(payload.user.created, loadedMember?.userCreatedDate)
            Assert.willBeEqual(payload.user.updated, loadedMember?.userUpdatedDate)
            Assert.willBeEqual(payload.user.lastActiveDate, loadedMember?.lastActiveDate)
            Assert.willBeEqual(payload.roleRawValue, loadedMember?.channelRole.rawValue)
            Assert.willBeEqual(payload.created, loadedMember?.memberCreatedDate)
            Assert.willBeEqual(payload.updated, loadedMember?.memberUpdatedDate)
            //      Assert.willBeEqual(payload.user.isInvited, loadedMember?.isInvited)
            //      Assert.willBeEqual(payload.user.inviteAcceptedDate, loadedMember?.inviteAcceptedDate)
            //      Assert.willBeEqual(payload.user.inviteRejectedDate, loadedMember?.inviteRejectedDate)
        }
    }
}
