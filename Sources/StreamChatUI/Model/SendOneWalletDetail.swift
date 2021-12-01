//
//  SendOneWallet.swift
//  Timeless-wallet
//
//  Created by Ajay Ghodadra on 01/12/21.
//

import Foundation
import StreamChat

struct SendOneWalletDetail {
    // MARK: - Variables
    var myName: String?
    var myWalletAddress: String?
    var recipientName: String?
    var recipientAddress: String?
    var recipientImageUrl: URL?
    var myImageUrl: URL?
    var transferAmount: Float?
    var txId: String?

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
