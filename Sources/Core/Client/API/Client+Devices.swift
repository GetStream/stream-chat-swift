//
//  Client+Devices.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Devices

public extension Client {
    
    /// Add a device for Push Notifications.
    /// - Parameters:
    ///   - deviceToken: a device token.
    ///   - completion: an empty completion block.
    func addDevice(deviceToken: Data, _ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.addDevice(deviceToken: deviceToken).bindOnce(to: completion)
    }
    
    /// Add a device for Push Notifications.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: an empty completion block.
    func addDevice(deviceId: String, _ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.addDevice(deviceId: deviceId).bindOnce(to: completion)
    }
    
    /// Request az list if devices.
    /// - Parameter completion: a completion block wiith `[Device]`.
    func requestDevices(_ completion: @escaping Client.Completion<[Device]>) {
        return rx.requestDevices().bindOnce(to: completion)
    }
    
    /// Remove a device.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: an empty completion block.
    func removeDevice(deviceId: String, _ completion: @escaping Client.Completion<Void> = { _ in }) {
        return rx.removeDevice(deviceId: deviceId).bindOnce(to: completion)
    }
}
