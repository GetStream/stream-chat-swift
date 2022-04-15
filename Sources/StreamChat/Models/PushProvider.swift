//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A unique identifier of a push provider.
public typealias PushProviderId = String

/// A type that represents the supported push providers.
public enum PushProvider {
    case firebase(token: String)
    case apn(token: Data)
    
    var pushProviderId: PushProviderId {
        switch self {
        case .firebase:
            return "firebase"
        case .apn:
            return "apn"
        }
    }
    
    var deviceToken: DeviceId {
        switch self {
        case .firebase(let token):
            return token
        case .apn(let token):
            return token.deviceToken
        }
    }
}
