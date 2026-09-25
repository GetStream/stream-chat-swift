//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension WSAuthMessage {
    convenience init(token: Token, userInfo: UserInfo) {
        self.init(
            products: ["chat"],
            token: token.rawValue,
            userDetails: ConnectUserDetailsRequest(userInfo: userInfo)
        )
    }
}

extension ConnectUserDetailsRequest {
    convenience init(userInfo: UserInfo) {
        self.init(
            custom: userInfo.extraData.isEmpty ? nil : userInfo.extraData,
            id: userInfo.id,
            image: userInfo.imageURL?.absoluteString,
            invisible: userInfo.isInvisible,
            language: userInfo.language?.languageCode,
            name: userInfo.name,
            privacySettings: userInfo.privacySettings
        )
    }
}
