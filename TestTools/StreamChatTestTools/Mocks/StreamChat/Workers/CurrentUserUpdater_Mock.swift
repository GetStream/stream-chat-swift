//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

/// Mock implementation of `UserUpdater`
final class CurrentUserUpdater_Mock: CurrentUserUpdater {
    @Atomic var updateUserData_currentUserId: UserId?
    @Atomic var updateUserData_name: String?
    @Atomic var updateUserData_imageURL: URL?
    @Atomic var updateUserData_userExtraData: [String: RawJSON]?
    @Atomic var updateUserData_privacySettings: UserPrivacySettings?
    @Atomic var updateUserData_unset: Set<String>?
    @Atomic var updateUserData_teamsRole: [TeamId: UserRole]?
    @Atomic var updateUserData_completion: ((Error?) -> Void)?

    @Atomic var addDevice_id: DeviceId?
    @Atomic var addDevice_currentUserId: UserId?
    @Atomic var addDevice_pushProvider: PushProvider?
    @Atomic var addDevice_providerName: String?
    @Atomic var addDevice_completion: ((Error?) -> Void)?

    @Atomic var removeDevice_id: String?
    @Atomic var removeDevice_currentUserId: UserId?
    @Atomic var removeDevice_completion: ((Error?) -> Void)?

    @Atomic var fetchDevices_currentUserId: UserId?
    @Atomic var fetchDevices_completion: ((Result<[Device], Error>) -> Void)?

    @Atomic var markAllRead_completion: ((Error?) -> Void)?
    @Atomic var markAllRead_completion_result: Result<Void, Error>?
    
    @Atomic var deleteAllLocalAttachmentDownloads_completion: ((Error?) -> Void)?
    @Atomic var deleteAllLocalAttachmentDownloads_completion_result: Result<Void, Error>?

    @Atomic var loadAllUnreads_completion: ((Result<CurrentUserUnreads, Error>) -> Void)?

    @Atomic var setPushPreference_preference: PushPreferenceRequestPayload?
    @Atomic var setPushPreference_completion: ((Result<PushPreference, Error>) -> Void)?
    @Atomic var setPushPreference_completion_result: Result<PushPreference, Error>?

    @Atomic var markChannelsDelivered_deliveredMessages: [MessageDeliveryInfo]?
    @Atomic var markChannelsDelivered_callCount = 0
    @Atomic var markChannelsDelivered_completion: ((Error?) -> Void)?
    @Atomic var markChannelsDelivered_completion_result: Error?

    override func updateUserData(
        currentUserId: UserId,
        name: String?,
        imageURL: URL?,
        privacySettings: UserPrivacySettings?,
        role: UserRole?,
        teamsRole: [TeamId: UserRole]?,
        userExtraData: [String: RawJSON]?,
        unset: Set<String>,
        completion: ((Error?) -> Void)? = nil
    ) {
        updateUserData_currentUserId = currentUserId
        updateUserData_name = name
        updateUserData_imageURL = imageURL
        updateUserData_userExtraData = userExtraData
        updateUserData_privacySettings = privacySettings
        updateUserData_unset = unset
        updateUserData_teamsRole = teamsRole
        updateUserData_completion = completion
    }

    override func addDevice(
        deviceId: DeviceId,
        pushProvider: PushProvider,
        providerName: String?,
        currentUserId: UserId,
        completion: ((Error?) -> Void)? = nil
    ) {
        addDevice_id = deviceId
        addDevice_currentUserId = currentUserId
        addDevice_pushProvider = pushProvider
        addDevice_providerName = providerName
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

    override func fetchDevices(currentUserId: UserId, completion: ((Result<[Device], Error>) -> Void)? = nil) {
        fetchDevices_currentUserId = currentUserId
        fetchDevices_completion = completion
    }
    
    override func deleteAllLocalAttachmentDownloads(completion: @escaping ((any Error)?) -> Void) {
        deleteAllLocalAttachmentDownloads_completion = completion
        deleteAllLocalAttachmentDownloads_completion_result?.invoke(with: completion)
    }

    override func loadAllUnreads(completion: @escaping ((Result<CurrentUserUnreads, Error>) -> Void)) {
        loadAllUnreads_completion = completion
    }

    override func setPushPreference(
        _ preference: PushPreferenceRequestPayload,
        completion: @escaping (Result<PushPreference, Error>) -> Void
    ) {
        setPushPreference_preference = preference
        setPushPreference_completion = completion
        setPushPreference_completion_result?.invoke(with: completion)
    }

    override func markMessagesAsDelivered(
        _ messages: [MessageDeliveryInfo],
        completion: ((Error?) -> Void)? = nil
    ) {
        markChannelsDelivered_callCount += 1
        markChannelsDelivered_deliveredMessages = messages
        if let completion = markChannelsDelivered_completion {
            completion(markChannelsDelivered_completion_result)
        } else {
            markChannelsDelivered_completion = completion
        }
    }

    // Cleans up all recorded values
    func cleanUp() {
        updateUserData_currentUserId = nil
        updateUserData_name = nil
        updateUserData_imageURL = nil
        updateUserData_privacySettings = nil
        updateUserData_userExtraData = nil
        updateUserData_unset = nil
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
        markAllRead_completion_result = nil
        
        deleteAllLocalAttachmentDownloads_completion = nil
        deleteAllLocalAttachmentDownloads_completion_result = nil

        loadAllUnreads_completion = nil

        setPushPreference_preference = nil
        setPushPreference_completion = nil
        setPushPreference_completion_result = nil

        markChannelsDelivered_deliveredMessages = nil
        markChannelsDelivered_completion = nil
    }

    override func markAllRead(completion: ((Error?) -> Void)? = nil) {
        markAllRead_completion = completion
        markAllRead_completion_result?.invoke(with: completion)
    }
}
