//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `UserUpdater`
final class UserUpdaterMock<ExtraData: ExtraDataTypes>: UserUpdater<ExtraData> {
    @Atomic var muteUser_userId: UserId?
    @Atomic var muteUser_completion: ((Error?) -> Void)?

    @Atomic var unmuteUser_userId: UserId?
    @Atomic var unmuteUser_completion: ((Error?) -> Void)?

    @Atomic var loadUser_userId: UserId?
    @Atomic var loadUser_completion: ((Error?) -> Void)?

    override func muteUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        muteUser_userId = userId
        muteUser_completion = completion
    }
    
    override func unmuteUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        unmuteUser_userId = userId
        unmuteUser_completion = completion
    }
    
    override func loadUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        loadUser_userId = userId
        loadUser_completion = completion
    }
}
