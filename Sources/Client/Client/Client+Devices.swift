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
    @discardableResult
    func addDevice(deviceToken: Data, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        addDevice(deviceId: deviceToken.deviceToken, completion)
    }
    
    /// Add a device for Push Notifications.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: an empty completion block.
    @discardableResult
    func addDevice(deviceId: String, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        let device = Device(deviceId)
        
        let completion = doBefore(completion) { [unowned self] _ in
            self.userAtomic.append(to: \.devices, device)
            self.userAtomic.currentDevice = device
            self.logger?.log("📱 Device added with id: \(deviceId)")
        }
        
        return request(endpoint: .addDevice(deviceId: deviceId, self.user), completion)
    }
    
    /// Gets a list of user devices.
    /// - Parameter completion: a completion block wiith `[Device]`.
    @discardableResult
    func devices(_ completion: @escaping Client.Completion<[Device]>) -> Cancellable {
        let completion = doBefore(completion) { [unowned self] devices in
            self.userAtomic.devices = devices
            self.logger?.log("📱 Devices updated")
        }
        
        return request(endpoint: .devices(user)) { (result: Result<DevicesResponse, ClientError>) in
            completion(result.map(to: \.devices))
        }
    }
    
    /// Remove a device.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: an empty completion block.
    @discardableResult
    func removeDevice(deviceId: String, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        let completion = doBefore(completion) { [unowned self] devices in
            self.userAtomic.update { oldUser in
                if let index = self.user.devices.firstIndex(where: { $0.id == deviceId }) {
                    var currentUser = oldUser
                    let removedDevice = currentUser.devices.remove(at: index)
                    
                    if let currentDevice = currentUser.currentDevice, currentDevice == removedDevice {
                        currentUser.currentDevice = nil
                    }
                    
                    return currentUser
                }
                
                return oldUser
            }
            
            self.logger?.log("📱 Device removed with id: \(deviceId)")
        }
        
        return request(endpoint: .removeDevice(deviceId: deviceId, user), completion)
    }
}
