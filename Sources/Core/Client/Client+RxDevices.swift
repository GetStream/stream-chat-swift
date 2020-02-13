//
//  Client+RxDevices.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Devices

public extension Reactive where Base == Client {
    
    /// Add a device for Push Notifications.
    /// - Parameter deviceToken: a device token.
    /// - Returns: an observable completion.
    func addDevice(deviceToken: Data) -> Observable<EmptyData> {
        request({ [unowned base] completion in
            base.addDevice(deviceToken: deviceToken, completion)
        })
    }
    
    /// Add a device for Push Notifications.
    /// - Parameter deviceId: a Push Notifications device identifier.
    /// - Returns: an observable completion.
    func addDevice(deviceId: String) -> Observable<EmptyData> {
        request({ [unowned base] completion in
            base.addDevice(deviceId: deviceId, completion)
        })
    }
    
    /// Request a list if devices.
    /// - Returns: an observable list of devices.
    func devices() -> Observable<[Device]> {
        request({ [unowned base] completion in
            base.devices(completion)
        })
    }
    
    /// Remove a device.
    /// - Parameter deviceId: a Push Notifications device identifier.
    /// - Returns: an observable empty data.
    func removeDevice(deviceId: String) -> Observable<EmptyData> {
        request({ [unowned base] completion in
            base.removeDevice(deviceId: deviceId, completion)
        })
    }
}
