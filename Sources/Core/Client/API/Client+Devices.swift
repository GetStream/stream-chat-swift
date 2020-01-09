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
    ///   - completion: a completion block (see `EmptyClientCompletion`).
    /// - Returns: a subscription.
    func addDevice(deviceToken: Data, _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.addDevice(deviceToken: deviceToken).bind(to: completion)
    }
    
    /// Add a device for Push Notifications.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: a completion block (see `EmptyClientCompletion`).
    /// - Returns: an observable completion.
    func addDevice(deviceId: String, _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.addDevice(deviceId: deviceId).bind(to: completion)
    }
    
    /// Request az list if devices.
    /// - Parameter completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    func requestDevices(_ completion: @escaping ClientCompletion<DevicesResponse>) -> Subscription {
        return rx.requestDevices().bind(to: completion)
    }
    
    /// Remove a device.
    ///
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: a completion block (see `EmptyClientCompletion`).
    /// - Returns: a subscription.
    func removeDevice(deviceId: String, _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return rx.removeDevice(deviceId: deviceId).bind(to: completion)
    }
}
