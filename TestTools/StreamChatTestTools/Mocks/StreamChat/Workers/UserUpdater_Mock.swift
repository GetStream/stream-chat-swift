//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `UserUpdater`
final class UserUpdater_Mock: UserUpdater {
    @Atomic var muteUser_userId: UserId?
    @Atomic var muteUser_completion: ((Error?) -> Void)?
    @Atomic var muteUser_completion_result: Result<Void, Error>?

    @Atomic var unmuteUser_userId: UserId?
    @Atomic var unmuteUser_completion: ((Error?) -> Void)?
    @Atomic var unmuteUser_completion_result: Result<Void, Error>?

    @Atomic var loadUser_userId: UserId?
    @Atomic var loadUser_completion: ((Error?) -> Void)?
    @Atomic var loadUser_completion_result: Result<Void, Error>?

    @Atomic var flagUser_flag: Bool?
    @Atomic var flagUser_userId: UserId?
    @Atomic var flagUser_completion: ((Error?) -> Void)?
    @Atomic var flagUser_completion_result: Result<Void, Error>?
    
    @Atomic var blockUser_userId: UserId?
    @Atomic var blockUser_completion: ((Error?) -> Void)?
    @Atomic var blockUser_completion_result: Result<Void, Error>?

    @Atomic var unblockUser_userId: UserId?
    @Atomic var unblockUser_completion: ((Error?) -> Void)?
    @Atomic var unblockUser_completion_result: Result<Void, Error>?

    override func muteUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        muteUser_userId = userId
        muteUser_completion = completion
        muteUser_completion_result?.invoke(with: completion)
    }

    override func unmuteUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        unmuteUser_userId = userId
        unmuteUser_completion = completion
        unmuteUser_completion_result?.invoke(with: completion)
    }

    override func loadUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        loadUser_userId = userId
        loadUser_completion = completion
        loadUser_completion_result?.invoke(with: completion)
    }

    override func flagUser(_ flag: Bool, with userId: UserId, completion: ((Error?) -> Void)? = nil) {
        flagUser_flag = flag
        flagUser_userId = userId
        flagUser_completion = completion
        flagUser_completion_result?.invoke(with: completion)
    }
    
    override func blockUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        blockUser_userId = userId
        blockUser_completion = completion
        blockUser_completion_result?.invoke(with: completion)
    }

    override func unblockUser(_ userId: UserId, completion: ((Error?) -> Void)? = nil) {
        unblockUser_userId = userId
        unblockUser_completion = completion
        unblockUser_completion_result?.invoke(with: completion)
    }

    // Cleans up all recorded values
    func cleanUp() {
        muteUser_userId = nil
        muteUser_completion = nil
        muteUser_completion_result = nil

        unmuteUser_userId = nil
        unmuteUser_completion = nil
        unmuteUser_completion_result = nil

        loadUser_userId = nil
        loadUser_completion = nil
        loadUser_completion_result = nil

        flagUser_flag = nil
        flagUser_userId = nil
        flagUser_completion = nil
        flagUser_completion_result = nil
        
        blockUser_userId = nil
        blockUser_completion = nil
        blockUser_completion_result = nil

        unblockUser_userId = nil
        unblockUser_completion = nil
        unblockUser_completion_result = nil
    }
}
