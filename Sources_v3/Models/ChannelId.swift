//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a unique identifier of a `ChatChannel`.
///
/// It reflects channel's type and a unique id.
///
public struct ChannelId: Hashable, CustomStringConvertible {
    private static let any = "*"
    private static let separator: Character = ":"
    
    let rawValue: String
    
    /// Returns `true` if the channel id matches "all" channels.
    public var isAny: Bool { rawValue == ChannelType.unknown.rawValue + String(Self.separator) + Self.any }
    
    /// Creates a new `ChannelId` value.
    ///
    /// - Parameters:
    ///     - type: A type of the channel the `ChannelId` represents.
    ///     - id: An id of the channel the `ChannelId` represents.
    ///
    public init(type: ChannelType, id: String) {
        rawValue = type.rawValue + "\(Self.separator)" + (id.isEmpty ? ChannelId.any : id)
    }
    
    init(cid: String) throws {
        if cid == ChannelId.any {
            self.init(type: .unknown, id: Self.any)
            return
        }
        
        if cid.contains(ChannelId.separator) {
            let channelPair = cid.split(separator: ChannelId.separator)
            let type = ChannelType(rawValue: String(channelPair[0]))
            let id = String(channelPair[1])
            self.init(type: type, id: id)
        } else {
            throw ClientError.InvalidChannelId("The channel id has invalid format and can't be decoded: \(cid)")
        }
    }
    
    public var description: String { rawValue }
}

public extension ChannelId {
    /// The type of the channel the id belongs to.
    var type: ChannelType {
        guard rawValue.contains(ChannelId.separator) else {
            return .unknown
        }
        
        let channelPair = rawValue.split(separator: ChannelId.separator)
        return ChannelType(rawValue: String(channelPair[0]))
    }
    
    /// The id of the channel without the encoded type information.
    var id: String {
        guard rawValue.contains(ChannelId.separator) else {
            return ChannelId.any
        }
        
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
        try container.encode(id == ChannelId.any ? ChannelId.any : rawValue)
    }
}

extension ClientError {
    public class InvalidChannelId: ClientError {}
}
