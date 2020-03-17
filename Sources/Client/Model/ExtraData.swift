//
//  ExtraData.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 06/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// An extra data container.
public struct ExtraData: Codable {
    
    /// An extra data.
    public let object: Codable
    
    /// Init an extra data with custom data.
    /// - Parameter object: an extra data for encoding.
    public init?(_ object: Codable?) {
        if let object = object {
            self.object = object
        } else {
            return nil
        }
    }
    
    /// Encodes an extra data to the Data.
    /// - Returns: an encoded extra data.
    public func encode() -> Data? {
        try? JSONEncoder.default.encode(self)
    }
    
    public func encode(to encoder: Encoder) throws {
        try object.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        object = EmptyData()
    }
    
    /// Decode an extra data from decoder with a given decodable type key.
    /// - Parameters:
    ///   - decoder: the decoder to read data from.
    ///   - key: a decodable type key.
    public init?(from decoder: Decoder, forType type: Codable.Type?) throws {
        guard let codableType = type else {
            return nil
        }
        
        self.init(try codableType.init(from: decoder))
    }
}

// MARK: - Decoder Wrapperss

public extension ExtraData {
    
    /// A custom data wrapper.
    class Wrapper: Decodable {
        fileprivate(set) var object: Codable?
        
        /// Decode a custom data.
        /// - Parameter data: a data
        /// - Returns: a decoded object.
        public static func decode(_ data: Data?) -> Codable? {
            guard let data = data else {
                return nil
            }
            
            return try? JSONDecoder.default.decode(Self.self, from: data).object
        }
        
        public required init(from decoder: Decoder) throws {}
    }
    
    /// A custom user data wrapper.
    final class UserWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = try? ExtraData(from: decoder, forType: User.extraDataType)?.object
        }
    }
    
    /// A custom channel data wrapper.
    final class ChannelWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = try? ExtraData(from: decoder, forType: Channel.extraDataType)?.object
        }
    }
    
    /// A custom message data wrapper.
    final class MessageWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = try? ExtraData(from: decoder, forType: Message.extraDataType)?.object
        }
    }
    
    /// A custom attachment data wrapper.
    final class AttachmentWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = try? ExtraData(from: decoder, forType: Attachment.extraDataType)?.object
        }
    }
    
    /// A custom reaction data wrapper.
    final class ReactionWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = try? ExtraData(from: decoder, forType: Reaction.extraDataType)?.object
        }
    }
}
