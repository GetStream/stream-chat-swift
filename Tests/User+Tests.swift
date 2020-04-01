//
//  User+Tests.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 22/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatClient

extension User {
    static let user1 = User(id: "broken-waterfall-5")
    static let user2 = User(id: "noisy-mountain-3")
}

extension Token {
    static let token1 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
    static let token2 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoibm9pc3ktbW91bnRhaW4tMyJ9.GAhzrzo8SsDn_RGzX4Fob5bZB0nKXXPKya8okbr9WB0"
}
