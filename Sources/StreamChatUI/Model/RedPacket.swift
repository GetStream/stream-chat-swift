//
//  RedPacket.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public struct RedPacket {
    // MARK: - Variables
    public var title: String?
    public var myName: String?
    public var myWalletAddress: String?
    public var myImageUrl: URL?
    public var channelUsers: Int?
    public var amount: Float? // max/min ONE
    public var minWeiAmount: String? // wie unit BigUIng (String)
    public var maxWeiAmount: String? // wie unit BigUIng (String)
    public var minOne: String?
    public var maxOne: String?
    public var usdAmount: Double? // ONE to USD
    public var channelId: String?
    public var participantsCount: Int?
    public var endTime: String?
    public var packetId: String?
    public init() {
    }

    func toDictionary() -> [String: RawJSON] {
        var dictOut = [String: RawJSON]()
        dictOut["title"] = .string(title ?? "")
        dictOut["myName"] = .string(myName ?? "")
        dictOut["myWalletAddress"] = .string(myWalletAddress ?? "")
        dictOut["myImageUrl"] = .string(myImageUrl?.absoluteString ?? "")
        dictOut["channelUsers"] = .string("\(channelUsers ?? 0)")
        dictOut["amount"] = .string("\(amount ?? 0)")
        dictOut["minWeiAmount"] = .string(minWeiAmount ?? "0")
        dictOut["maxWeiAmount"] = .string(maxWeiAmount ?? "0")
        dictOut["usdAmount"] = .number(usdAmount ?? 0)
        dictOut["channelId"] = .string(channelId ?? "")
        dictOut["participantsCount"] = .string("\(participantsCount ?? 0)")
        dictOut["minOne"] = .string(minOne ?? "0")
        dictOut["maxOne"] = .string(maxOne ?? "0")
        dictOut["endTime"] = .string(endTime ?? "0")
        dictOut["packetId"] = .string(packetId ?? "")
        return dictOut
    }
}
