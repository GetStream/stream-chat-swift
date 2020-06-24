//
// ExtraData.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing no extra data for the given model object.
public struct NoExtraData: Codable, Hashable, UserExtraData, ChannelExtraData, MessageExtraData {}

/// The extra data type with `name` and `imageURL` properties.
public struct NameAndImageExtraData: ChannelExtraData, UserExtraData {
    private enum CodingKeys: String, CodingKey {
        case name
        case imageURL = "image"
    }
    
    public let name: String?
    public let imageURL: URL?
    
    public init(name: String? = nil, imageURL: URL? = nil) {
        self.name = name
        self.imageURL = imageURL
    }
    
    public init(from decoder: Decoder) throws {
        // Unfortunatelly, the built-in URL decoder fails, if the string is empty. We need to
        // provide custom decoding to handle URL? as expected.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL).flatMap(URL.init(string:))
    }
}
