//
// Message.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageModel<CustomData: Codable & Hashable> {
  let id: String
}

public typealias Message = MessageModel<NoExtraMessageData>

public struct NoExtraMessageData: Codable, Hashable {}
