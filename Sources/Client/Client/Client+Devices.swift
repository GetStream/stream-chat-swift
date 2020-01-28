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
    func addDevice(deviceToken: Data, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        return addDevice(deviceId: deviceToken.deviceToken, completion)
    }
    
    /// Add a device for Push Notifications.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: an empty completion block.
    @discardableResult
    func addDevice(deviceId: String, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        let device = Device(deviceId)
        
        let completion = doBefore(completion) { [unowned self] _ in
            self.userAtomic.update { oldUser in
                var currentUser = oldUser
                currentUser.devices.append(device)
                currentUser.currentDevice = device
                return currentUser
            }
            
            self.logger?.log("📱 Device added with id: \(deviceId)")
        }
        
        return request(endpoint: .addDevice(deviceId: deviceId, self.user), completion)
    }
    
    /// Gets a list of user devices.
    /// - Parameter completion: a completion block wiith `[Device]`.
    @discardableResult
    func devices(_ completion: @escaping Client.Completion<[Device]>) -> URLSessionTask {
        let completion = doBefore(completion) { [unowned self] devices in
            self.userAtomic.update { oldUser in
                var currentUser = oldUser
                currentUser.devices = devices
                return currentUser
            }
            
            self.logger?.log("📱 Devices updated")
        }
        
        return request(endpoint: .devices(user)) { (result: Result<DevicesResponse, ClientError>) in
            completion(result.map({ $0.devices }))
        }
    }
    
    /// Remove a device.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: an empty completion block.
    @discardableResult
    func removeDevice(deviceId: String, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        let completion = doBefore(completion) { [unowned self] devices in
            self.userAtomic.update { oldUser in
                if let index = self.user.devices.firstIndex(where: { $0.id == deviceId }) {
                    var currentUser = oldUser
                    currentUser.devices.remove(at: index)
                    return currentUser
                }
                
                return oldUser
            }
            
            self.logger?.log("📱 Device removed with id: \(deviceId)")
        }
        
        return request(endpoint: .removeDevice(deviceId: deviceId, user), completion)
    }
}
