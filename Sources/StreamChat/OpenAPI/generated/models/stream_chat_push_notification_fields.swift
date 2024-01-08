//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPushNotificationFields: Codable, Hashable {
    public var version: String
    
    public var xiaomi: StreamChatXiaomiConfigFields
    
    public var apn: StreamChatAPNConfigFields
    
    public var firebase: StreamChatFirebaseConfigFields
    
    public var huawei: StreamChatHuaweiConfigFields
    
    public var offlineOnly: Bool
    
    public var providers: [StreamChatPushProvider?]?
    
    public init(version: String, xiaomi: StreamChatXiaomiConfigFields, apn: StreamChatAPNConfigFields, firebase: StreamChatFirebaseConfigFields, huawei: StreamChatHuaweiConfigFields, offlineOnly: Bool, providers: [StreamChatPushProvider?]?) {
        self.version = version
        
        self.xiaomi = xiaomi
        
        self.apn = apn
        
        self.firebase = firebase
        
        self.huawei = huawei
        
        self.offlineOnly = offlineOnly
        
        self.providers = providers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case version
        
        case xiaomi
        
        case apn
        
        case firebase
        
        case huawei
        
        case offlineOnly = "offline_only"
        
        case providers
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(version, forKey: .version)
        
        try container.encode(xiaomi, forKey: .xiaomi)
        
        try container.encode(apn, forKey: .apn)
        
        try container.encode(firebase, forKey: .firebase)
        
        try container.encode(huawei, forKey: .huawei)
        
        try container.encode(offlineOnly, forKey: .offlineOnly)
        
        try container.encode(providers, forKey: .providers)
    }
}
