//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `UserUpdater`
final class CurrentUserUpdater_Mock: CurrentUserUpdater {
    @Atomic var updateUserData_currentUserId: UserId?
    @Atomic var updateUserData_name: String?
    @Atomic var updateUserData_imageURL: URL?
    @Atomic var updateUserData_userExtraData: [String: RawJSON]?
    @Atomic var updateUserData_completion: ((Error?) -> Void)?
    
    @Atomic var addDevice_id: DeviceId?
    @Atomic var addDevice_currentUserId: UserId?
    @Atomic var addDevice_pushProvider: PushProvider?
    @Atomic var addDevice_completion: ((Error?) -> Void)?
    
    @Atomic var removeDevice_id: String?
    @Atomic var removeDevice_currentUserId: UserId?
    @Atomic var removeDevice_completion: ((Error?) -> Void)?
    
    @Atomic var fetchDevices_currentUserId: UserId?
    @Atomic var fetchDevices_completion: ((Error?) -> Void)?
    
    @Atomic var markAllRead_completion: ((Error?) -> Void)?
    
    override func updateUserData(
        currentUserId: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        userExtraData: [String: RawJSON]? = nil,
        completion: ((Error?) -> Void)? = nil
    ) {
        updateUserData_currentUserId = currentUserId
        updateUserData_name = name
        updateUserData_imageURL = imageURL
        updateUserData_userExtraData = userExtraData
        updateUserData_completion = completion
    }
    
    override func addDevice(
        deviceId: DeviceId,
        pushProvider: PushProvider,
        currentUserId: UserId,
        completion: ((Error?) -> Void)? = nil
    ) {
        addDevice_id = deviceId
        addDevice_currentUserId = currentUserId
        addDevice_pushProvider = pushProvider
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
        updateUserData_userExtraData = nil
        updateUserData_completion = nil
        
        addDevice_id = nil
        addDevice_currentUserId = nil
        addDevice_completion = nil
        
        removeDevice_id = nil
        removeDevice_currentUserId = nil
        removeDevice_completion = nil
        
        fetchDevices_currentUserId = nil
        fetchDevices_completion = nil
        
        markAllRead_completion = nil
    }
    
    override func markAllRead(completion: ((Error?) -> Void)? = nil) {
        markAllRead_completion = completion
    }
}
