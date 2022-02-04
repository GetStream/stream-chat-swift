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

    public var paymentType: PaymentType!
    public var extraData: [String: RawJSON]?

    public init(paymentType: PaymentType, extraData: [String: RawJSON]?) {
        self.paymentType = paymentType
        self.extraData = extraData
    }

    public enum PaymentType: String {
        case request = "Request"
        case pay = "Pay"
    }

    public enum PaymentTheme: String, CaseIterable {
        case none = "Default"
        case anniversary = "Anniversary"
        case birthday = "Birthday"
        case booze = "Booze"
        case gracias = "Gracias"
        case Jetaime = "Je t'aime"
        case holiday = "Holiday"

        public func getPaymentThemeUrl() -> String {
            switch self {
            case .none:
                return "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/shh.png"
            case .anniversary:
                return "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/celebrate.gif"
            case .birthday:
                return "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/bday.png"
            case .booze:
                return "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/cheers.gif"
            case .gracias:
                return "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/thanks.png"
            case .Jetaime:
                return "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/love.png"
            case .holiday:
                return "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/holiday.gif"
            }
        }
    }
}

extension WalletAttachmentPayload: Hashable {}

// MARK: - Encodable

extension WalletAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.paymentType.rawValue] = paymentType.map { .string($0.rawValue) }
        try values.encode(to: encoder)
    }
}

// MARK: - Decodable

extension WalletAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        let paymentType = try container.decodeIfPresent(String.self, forKey: .paymentType)
        self.init(
            paymentType: WalletAttachmentPayload.PaymentType(rawValue: paymentType ?? "") ?? .pay,
            extraData: try Self.decodeExtraData(from: decoder))
    }
}
