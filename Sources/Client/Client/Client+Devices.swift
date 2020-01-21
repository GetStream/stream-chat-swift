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
        guard let currentUser = user else {
            completion(.failure(.emptyUser))
            return .empty
        }
        
        let device = Device(deviceId)
        
        let completion = doBefore(completion) { [unowned self] _ in
            // Update the Client state.
            if let currentUser = self.user {
                var currentUser = currentUser
                currentUser.devices.append(device)
                currentUser.currentDevice = device
                self.user = currentUser
                self.logger?.log("📱 Device added with id: \(deviceId)")
            }
        }
        
        return request(endpoint: .addDevice(deviceId: deviceId, currentUser), completion)
    }
    
    /// Gets a list of user devices.
    /// - Parameter completion: a completion block wiith `[Device]`.
    @discardableResult
    func devices(_ completion: @escaping Client.Completion<[Device]>) -> URLSessionTask {
        guard let currentUser = user else {
            completion(.failure(.emptyUser))
            return .empty
        }
        
        let completion = doBefore(completion) { [unowned self] devices in
            if let currentUser = self.user {
                var currentUser = currentUser
                currentUser.devices = devices
                self.user = currentUser
                self.logger?.log("📱 Devices updated")
            }
        }
        
        return request(endpoint: .devices(currentUser)) { (result: Result<DevicesResponse, ClientError>) in
            completion(result.map({ $0.devices }))
        }
    }
    
    /// Remove a device.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: an empty completion block.
    @discardableResult
    func removeDevice(deviceId: String, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        guard let currentUser = user else {
            completion(.failure(.emptyUser))
            return .empty
        }
        
        let completion = doBefore(completion) { [unowned self] devices in
            if let index = currentUser.devices.firstIndex(where: { $0.id == deviceId }) {
                var currentUser = currentUser
                currentUser.devices.remove(at: index)
                self.user = currentUser
                self.logger?.log("📱 Device removed with id: \(deviceId)")
            }
        }
        
        return request(endpoint: .removeDevice(deviceId: deviceId, currentUser), completion)
    }
}
