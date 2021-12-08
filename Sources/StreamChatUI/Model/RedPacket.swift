//
//  RedPacket.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct RedPacket {
    // MARK: - Variables
    public var myName: String?
    public var myWalletAddress: String?
    public var myImageUrl: URL?
    public var channelUsers: Int?
    public var amount: Float? // max/min ONE
    public var minWeiAmount: Double? // wie unit BigUIng
    public var maxWeiAmount: Double? // wie unit BigUIng
    public var usdAmount: Double? // ONE to USD
    public var channelId: String?
    public var participantsCount: Int?

    public init() {
    }
}
