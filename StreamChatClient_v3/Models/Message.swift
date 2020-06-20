//
// Message.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias MessageId = String

public struct MessageModel<ExtraData: MessageExtraData> {
    let id: MessageId
}

public typealias Message = MessageModel<NoExtraData>

public protocol MessageExtraData: Codable & Hashable {}
