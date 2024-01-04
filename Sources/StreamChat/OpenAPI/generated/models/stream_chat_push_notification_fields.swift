//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPushNotificationFields: Codable, Hashable {
    public var offlineOnly: Bool
    
    public var providers: [StreamChatPushProvider?]?
    
    public var version: String
    
    public var xiaomi: StreamChatXiaomiConfigFields
    
    public var apn: StreamChatAPNConfigFields
    
    public var firebase: StreamChatFirebaseConfigFields
    
    public var huawei: StreamChatHuaweiConfigFields
    
    public init(offlineOnly: Bool, providers: [StreamChatPushProvider?]?, version: String, xiaomi: StreamChatXiaomiConfigFields, apn: StreamChatAPNConfigFields, firebase: StreamChatFirebaseConfigFields, huawei: StreamChatHuaweiConfigFields) {
        self.offlineOnly = offlineOnly
        
        self.providers = providers
        
        self.version = version
        
        self.xiaomi = xiaomi
        
        self.apn = apn
        
        self.firebase = firebase
        
        self.huawei = huawei
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case offlineOnly = "offline_only"
        
        case providers
        
        case version
        
        case xiaomi
        
        case apn
        
        case firebase
        
        case huawei
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(offlineOnly, forKey: .offlineOnly)
        
        try container.encode(providers, forKey: .providers)
        
        try container.encode(version, forKey: .version)
        
        try container.encode(xiaomi, forKey: .xiaomi)
        
        try container.encode(apn, forKey: .apn)
        
        try container.encode(firebase, forKey: .firebase)
        
        try container.encode(huawei, forKey: .huawei)
    }
}
