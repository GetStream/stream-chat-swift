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
    /// A custom extra data type.
    public enum DecodableType {
        /// A user.
        case user(Codable.Type)
        /// A channel.
        case channel(Codable.Type)
        /// A message.
        case message(Codable.Type)
        /// An attachment.
        case attachment(Codable.Type)
        /// A reaction.
        case reaction(Codable.Type)

        /// Checks if the decodable type is a custom user extra data type.
        public var isUser: Bool {
            if case .user = self {
                return true
            }
            
            return false
        }
        
        /// Checks if the decodable type is a custom channel extra data type.
        public var isChannel: Bool {
            if case .channel = self {
                return true
            }
            
            return false
        }
        
        /// Checks if the decodable type is a custom message extra data type.
        public var isMessage: Bool {
            if case .message = self {
                return true
            }
            
            return false
        }
        
        /// Checks if the decodable type is a custom attachment extra data type.
        public var isAttachment: Bool {
            if case .attachment = self {
                return true
            }
            
            return false
        }
        
        /// Checks if the decodable type is a custom attachment extra data type.
        public var isReaction: Bool {
            if case .reaction = self {
                return true
            }
            
            return false
        }
        
        public func codableType() -> Codable.Type {
            switch self {
            case .user(let codableType),
                 .channel(let codableType),
                 .message(let codableType),
                 .attachment(let codableType),
                 .reaction(let codableType):
                return codableType
            }
        }
        
        /// Decode an extra data with a given decoder.
        /// - Parameters:
        ///   - decoder: a decoder.
        ///   - decodableType: a custom decodable type.
        /// - Returns: an extra data.
        func decode(from decoder: Decoder) -> Codable? {
            return try? codableType().init(from: decoder)
        }
    }
    
    /// A list of a custom extra data type.
    public static var decodableTypes: [DecodableType] = []
    
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
        return try? JSONEncoder.default.encode(self)
    }
    
    public func encode(to encoder: Encoder) throws {
        try object.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        object = EmptyData()
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
            object = ExtraData.decodableTypes.first(where: { $0.isUser })?.decode(from: decoder)
        }
    }
    
    /// A custom channel data wrapper.
    final class ChannelWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = ExtraData.decodableTypes.first(where: { $0.isChannel })?.decode(from: decoder)
        }
    }
    
    /// A custom message data wrapper.
    final class MessageWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = ExtraData.decodableTypes.first(where: { $0.isMessage })?.decode(from: decoder)
        }
    }
    
    /// A custom attachment data wrapper.
    final class AttachmentWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = ExtraData.decodableTypes.first(where: { $0.isAttachment })?.decode(from: decoder)
        }
    }
    
    /// A custom reaction data wrapper.
    final class ReactionWrapper: Wrapper {
        required init(from decoder: Decoder) throws {
            try super.init(from: decoder)
            object = ExtraData.decodableTypes.first(where: { $0.isReaction })?.decode(from: decoder)
        }
    }
}
