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
    public var recipientName: String?
    public var recipientAddress: String?
    public var recipientImageUrl: URL?
    public var myImageUrl: URL?

    public init() {
    }
}
