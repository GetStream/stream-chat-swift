//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `UserUpdater`
final class CurrentUserUpdaterMock: CurrentUserUpdater<ExtraData> {
    @Atomic var updateUserData_currentUserId: UserId?
    @Atomic var updateUserData_name: String?
    @Atomic var updateUserData_imageURL: URL?
    @Atomic var updateUserData_userExtraData: CustomData = .defaultValue
    @Atomic var updateUserData_completion: ((Error?) -> Void)?
    
    @Atomic var addDevice_token: Data?
    @Atomic var addDevice_currentUserId: UserId?
    @Atomic var addDevice_completion: ((Error?) -> Void)?
    
    @Atomic var removeDevice_id: String?
    @Atomic var removeDevice_currentUserId: UserId?
    @Atomic var removeDevice_completion: ((Error?) -> Void)?
    
    @Atomic var fetchDevices_currentUserId: UserId?
    @Atomic var fetchDevices_completion: ((Error?) -> Void)?
    
    override func updateUserData(
        currentUserId: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        userExtraData: CustomData = .defaultValue,
        completion: ((Error?) -> Void)? = nil
    ) {
        updateUserData_currentUserId = currentUserId
        updateUserData_name = name
        updateUserData_imageURL = imageURL
        updateUserData_userExtraData = userExtraData
        updateUserData_completion = completion
    }
    
    override func addDevice(
        token: Data,
        currentUserId: UserId,
        completion: ((Error?) -> Void)? = nil
    ) {
        addDevice_token = token
        addDevice_currentUserId = currentUserId
        addDevice_completion = completion
    }
    
    override func removeDevice(
        id: String,
        currentUserId: UserId,
        completion: ((Error?) -> Void)? = nil
    ) {
        removeDevice_id = id
        removeDevice_currentUserId = currentUserId
        removeDevice_completion = completion
    }
    
    override func fetchDevices(currentUserId: UserId, completion: ((Error?) -> Void)? = nil) {
        fetchDevices_currentUserId = currentUserId
        fetchDevices_completion = completion
    }
    
    // Cleans up all recorded values
    func cleanUp() {
        updateUserData_currentUserId = nil
        updateUserData_name = nil
        updateUserData_imageURL = nil
        updateUserData_userExtraData = .defaultValue
        updateUserData_completion = nil
        
        addDevice_token = nil
        addDevice_currentUserId = nil
        addDevice_completion = nil
        
        removeDevice_id = nil
        removeDevice_currentUserId = nil
        removeDevice_completion = nil
        
        fetchDevices_currentUserId = nil
        fetchDevices_completion = nil
    }
}
