//
//  ChatMessageWalletAttachment.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 29/12/21.
//

import Foundation

public typealias ChatMessageWalletAttachment = ChatMessageAttachment<ImageAttachmentPayload>

/// Represents a payload for attachments with `.wallet` type.
public struct WalletAttachmentPayload: AttachmentPayload {
    public static let type: AttachmentType = .wallet

    public var amount: String?
    public var paymentType: PaymentType!
    public var extraData: [String: RawJSON]?

    public init(amount: String?, paymentType: PaymentType) {
        self.amount = amount
        self.paymentType = paymentType
    }

    public enum PaymentType: String {
        case request = "Request"
        case pay = "Pay"
    }
}

extension WalletAttachmentPayload: Hashable {}

// MARK: - Encodable

extension WalletAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.amount.rawValue] = amount.map { .string($0) }
        values[AttachmentCodingKeys.paymentType.rawValue] = paymentType.map { .string($0.rawValue) }
        try values.encode(to: encoder)
    }
}

// MARK: - Decodable

extension WalletAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        let amount = try container.decodeIfPresent(String.self, forKey: .amount)
        let paymentType = try container.decodeIfPresent(String.self, forKey: .paymentType)
        self.init(amount: amount, paymentType: WalletAttachmentPayload.PaymentType(rawValue: paymentType ?? "") ?? .pay)
    }
}
