//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a unique identifier of a `ChatChannel`.
///
/// It reflects channel's type and a unique id.
///
public struct ChannelId: Hashable, CustomStringConvertible {
    private static let separator: Character = ":"
    
    let rawValue: String
    
    /// Creates a new `ChannelId` value.
    ///
    /// - Parameters:
    ///     - type: A type of the channel the `ChannelId` represents.
    ///     - id: An id of the channel the `ChannelId` represents.
    ///
    public init(type: ChannelType, id: String) {
        rawValue = type.rawValue + "\(Self.separator)" + id
    }
    
    public init(cid: String) throws {
        let channelPair = cid.split(separator: ChannelId.separator)
    
        guard
            channelPair.count == 2,
            !channelPair[0].replacingOccurrences(of: " ", with: "").isEmpty,
            !channelPair[1].replacingOccurrences(of: " ", with: "").isEmpty
        else {
            throw ClientError.InvalidChannelId("The channel id has invalid format and can't be decoded: \(cid)")
        }
        
        rawValue = cid
    }
 
    public var description: String { rawValue }
}

public extension ChannelId {
    /// The type of the channel the id belongs to.
    var type: ChannelType {
        let channelPair = rawValue.split(separator: ChannelId.separator)
        return ChannelType(rawValue: String(channelPair[0]))
    }
    
    /// The id of the channel without the encoded type information.
    var id: String {
        let channelPair = rawValue.split(separator: ChannelId.separator)
        return String(channelPair[1])
    }
}

extension ChannelId: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let cid = try container.decode(String.self)
        self = try ChannelId(cid: cid)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ClientError {
    public class InvalidChannelId: ClientError {}
}

extension ChannelId: APIPathConvertible {
    var apiPath: String { type.rawValue + "/" + id }
}
