//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `UserUpdater`
final class UserUpdaterMock: UserUpdater<ExtraData> {
    @Atomic var muteUser_userId: UserId?
    @Atomic var muteUser_completion: ((Error?) -> Void)?

    @Atomic var unmuteUser_userId: UserId?
    @Atomic var unmuteUser_completion: ((Error?) -> Void)?

    @Atomic var loadUser_userId: UserId?
    @Atomic var loadUser_completion: ((Error?) -> Void)?
    
    @Atomic var flagUser_flag: Bool?
    @Atomic var flagUser_userId: UserId?
    @Atomic var flagUser_completion: ((Error?) -> Void)?

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
    
    override func flagUser(_ flag: Bool, with userId: UserId, completion: ((Error?) -> Void)? = nil) {
        flagUser_flag = flag
        flagUser_userId = userId
        flagUser_completion = completion
    }
    
    // Cleans up all recorded values
    func cleanUp() {
        muteUser_userId = nil
        muteUser_completion = nil
        
        unmuteUser_userId = nil
        unmuteUser_completion = nil
        
        loadUser_userId = nil
        loadUser_completion = nil
        
        flagUser_flag = nil
        flagUser_userId = nil
        flagUser_completion = nil
    }
}
