//
//  Client+RxDevices.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

public extension Reactive where Base == Client {
    
    // MARK: - Devices
    
    /// Add a device for Push Notifications.
    /// - Parameter deviceToken: a device token.
    /// - Returns: an observable completion.
    func addDevice(deviceToken: Data) -> Observable<Void> {
        return deviceToken.isEmpty
            ? .error(ClientError.emptyDeviceToken)
            : addDevice(deviceId: deviceToken.deviceToken)
    }
    
    /// Add a device for Push Notifications.
    /// - Parameter deviceId: a Push Notifications device identifier.
    /// - Returns: an observable completion.
    func addDevice(deviceId: String) -> Observable<Void> {
        let device = Device(deviceId)
        
        if user.devices.contains(where: { $0.id == deviceId }) {
            if user.currentDevice == nil {
                var user = user
                user.currentDevice = device
                base.user = user
            }
            
            return .empty()
        }
        
        return connectedRequest(endpoint: .addDevice(deviceId: deviceId, user))
            .do(onNext: { [unowned base] _ in
                var user = user
                user.devices.append(device)
                user.currentDevice = device
                base.user = user
                base.logger?.log("📱 Device added with id: \(deviceId)")
            })
            .map { (_: EmptyData) in Void() }
    }
    
    /// Request a list if devices.
    /// - Returns: an observable list of devices.
    func requestDevices() -> Observable<[Device]> {
        let request: Observable<DevicesResponse> = connectedRequest(endpoint: .devices(user))
        
        return request.map { $0.devices }
            .do(onNext: { [unowned base] devices in
                if let currentUser = User.current {
                    var user = currentUser
                    user.devices = devices
                    base.user = user
                    base.logger?.log("📱 Devices updated")
                }
            })
    }
    
    /// Remove a device.
    /// - Parameter deviceId: a Push Notifications device identifier.
    /// - Returns: an observable empty data.
    func removeDevice(deviceId: String) -> Observable<Void> {
        return connection.connected()
            .flatMapLatest({ [unowned base] _ -> Observable<EmptyData> in
                if currentUser.devices.firstIndex(where: { $0.id == deviceId }) != nil {
                    return self.connectedRequest(endpoint: .removeDevice(deviceId: deviceId, currentUser))
                }
                
                base.logger?.log("📱 Device id not found")
                
                return .empty()
            })
            .void()
            .do(onNext: { [unowned base] in
                if let index = currentUser.devices.firstIndex(where: { $0.id == deviceId }) {
                    var user = currentUser
                    user.devices.remove(at: index)
                    base.user = user
                    base.logger?.log("📱 Device removed with id: \(deviceId)")
                }
            })
    }
}
