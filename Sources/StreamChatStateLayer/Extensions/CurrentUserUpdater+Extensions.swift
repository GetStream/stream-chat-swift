//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(iOS 13.0, *)
extension CurrentUserUpdater {
    func addDevice(_ device: PushDevice, currentUserId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            addDevice(deviceId: device.deviceId, pushProvider: device.pushProvider, providerName: device.providerName, currentUserId: currentUserId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func removeDevice(id: DeviceId, currentUserId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            removeDevice(id: id, currentUserId: currentUserId) { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func fetchDevices(currentUserId: UserId) async throws -> [Device] {
        try await withCheckedThrowingContinuation { continuation in
            fetchDevices(currentUserId: currentUserId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func markAllRead(currentUserId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            markAllRead { error in
                continuation.resume(with: error)
            }
        }
    }
    
    func updateUserData(currentUserId: UserId, name: String?, imageURL: URL?, userExtraData: [String: RawJSON]?) async throws {
        try await withCheckedThrowingContinuation { continuation in
            updateUserData(currentUserId: currentUserId, name: name, imageURL: imageURL, userExtraData: userExtraData) { error in
                continuation.resume(with: error)
            }
        }
    }
}
