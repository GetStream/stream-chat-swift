//
//  SendOneWallet.swift
//  Timeless-wallet
//
//  Created by Ajay Ghodadra on 01/12/21.
//

import Foundation
import StreamChat

public struct SendOneWallet {
    // MARK: - Variables
    public var myName: String?
    public var myWalletAddress: String?
    public var recipientName: String?
    public var recipientAddress: String?
    public var recipientImageUrl: URL?
    public var myImageUrl: URL?
    public var transferAmount: Float?
    public var txId: String?

    public init() {
    }

    func toDictionary() -> [String: RawJSON] {
        var dictOut = [String: RawJSON]()
        dictOut["myName"] = .string(myName ?? "")
        dictOut["myWalletAddress"] = .string(myWalletAddress ?? "")
        dictOut["recipientName"] = .string(recipientName ?? "")
        dictOut["recipientAddress"] = .string(recipientAddress ?? "")
        dictOut["recipientImageUrl"] = .string(recipientImageUrl?.absoluteString ?? "")
        dictOut["myImageUrl"] = .string(myImageUrl?.absoluteString ?? "")
        dictOut["transferAmount"] = .number(Double(transferAmount ?? 0))
        dictOut["txId"] = .string(txId ?? "")
        return dictOut
    }
}
