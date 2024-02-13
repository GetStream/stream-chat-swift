//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PushNotificationFields: Codable, Hashable {
    public var offlineOnly: Bool
    public var version: String
    public var apn: APNConfigFields
    public var firebase: FirebaseConfigFields
    public var huawei: HuaweiConfigFields
    public var xiaomi: XiaomiConfigFields
    public var providers: [PushProvider?]? = nil

    public init(offlineOnly: Bool, version: String, apn: APNConfigFields, firebase: FirebaseConfigFields, huawei: HuaweiConfigFields, xiaomi: XiaomiConfigFields, providers: [PushProvider?]? = nil) {
        self.offlineOnly = offlineOnly
        self.version = version
        self.apn = apn
        self.firebase = firebase
        self.huawei = huawei
        self.xiaomi = xiaomi
        self.providers = providers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case offlineOnly = "offline_only"
        case version
        case apn
        case firebase
        case huawei
        case xiaomi
        case providers
    }
}
