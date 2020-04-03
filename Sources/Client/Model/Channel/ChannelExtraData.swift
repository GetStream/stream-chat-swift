//
//  ChannelExtraData.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 19/03/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel extra data protocol for custom channel properties.
/// The `name` and `imageURL` is a part of channel extra data properties.
public protocol ChannelExtraDataCodable: Codable {
    /// A channel name.
    var name: String? { get set }
    /// A channel image URL.
    var imageURL: URL? { get set }
}

/// A default channel extra data type with `name` and `imageURL` properties.
public struct ChannelExtraData: ChannelExtraDataCodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case imageURL = "image"
    }
    
    public var name: String?
    public var imageURL: URL?
    
    public init(name: String? = nil, imageURL: URL? = nil) {
        self.name = name
        self.imageURL = imageURL
    }
}
