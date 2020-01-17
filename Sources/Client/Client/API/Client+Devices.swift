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
        if deviceToken.isEmpty {
            completion(.failure(.emptyDeviceToken))
            return .empty
        }
        
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
        
        if currentUser.devices.contains(where: { $0.id == deviceId }) {
            if currentUser.currentDevice == nil {
                var currentUser = currentUser
                currentUser.currentDevice = device
                user = currentUser
            }
            
            completion(.success(.empty))
            return .empty
        }
        
        let completion = beforeCompletion(completion) { [unowned self] _ in
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
    
    /// Request az list if devices.
    /// - Parameter completion: a completion block wiith `[Device]`.
    @discardableResult
    func devices(_ completion: @escaping Client.Completion<[Device]>) -> URLSessionTask {
        guard let currentUser = user else {
            completion(.failure(.emptyUser))
            return .empty
        }
        
        let completion = beforeCompletion(completion, updateDevicesForCurrentUser)
        
        return request(endpoint: .devices(currentUser)) { (result: Result<DevicesResponse, ClientError>) in
            completion(result.map({ $0.devices }))
        }
    }
    
    private func updateDevicesForCurrentUser(_ devices: [Device]) {
        if let currentUser = user {
            var currentUser = currentUser
            currentUser.devices = devices
            user = currentUser
            logger?.log("📱 Devices updated")
        }
    }
    
    /// Remove a device.
    /// - Parameters:
    ///   - deviceId: a Push Notifications device identifier.
    ///   - completion: an empty completion block.
    @discardableResult
    func removeDevice(deviceId: String, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        guard user != nil else {
            completion(.failure(.emptyUser))
            return .empty
        }
        
        return devices { [unowned self] result in
            guard let devices = try? result.get() else {
                if let error = result.error {
                    completion(.failure(error))
                }
                
                return
            }
            
            self.updateDevicesForCurrentUser(devices)
            
            if devices.firstIndex(where: { $0.id == deviceId }) != nil {
                self.removeExistDevice(deviceId: deviceId, completion)
            } else {
                self.logger?.log("📱 Device id not found")
                completion(.success(.empty))
            }
        }
    }
    
    private func removeExistDevice(deviceId: String, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) {
        guard let currentUser = user else {
            completion(.failure(.emptyUser))
            return
        }
        
        let completion = beforeCompletion(completion) { [unowned self] devices in
            if let index = currentUser.devices.firstIndex(where: { $0.id == deviceId }) {
                var currentUser = currentUser
                currentUser.devices.remove(at: index)
                self.user = currentUser
                self.logger?.log("📱 Device removed with id: \(deviceId)")
            }
        }
        
        request(endpoint: .removeDevice(deviceId: deviceId, currentUser), completion)
    }
}
