//
// Message.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageModel<ExtraData: MessageExtraData> {
    let id: String
}

public typealias Message = MessageModel<NoExtraData>

public protocol MessageExtraData: Codable & Hashable {}
