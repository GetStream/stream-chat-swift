//
//  UserExtraData.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 20/03/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A user extra data protocol for custom user properties.
/// The `name` and `avatarURL` is a part of user extra data properties.
public protocol UserExtraDataCodable: Codable {
    /// A user name.
    var name: String? { get set }
    /// A user image URL.
    var avatarURL: URL? { get set }
}

/// A default user extra data type with `name` and `avatarURL` properties.
public struct UserExtraData: UserExtraDataCodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case avatarURL = "image"
    }
    
    public var name: String?
    public var avatarURL: URL?
    
    public init(name: String? = nil, avatarURL: URL? = nil) {
        self.name = name
        self.avatarURL = avatarURL
    }
}
