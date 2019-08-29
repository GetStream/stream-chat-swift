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
        /// A channel.
        case channel(Codable.Type)
        /// A message.
        case message(Codable.Type)
        /// An attachment.
        case attachment(Codable.Type)

        var isChannel: Bool {
            if case .channel = self {
                return true
            }
            
            return false
        }
        
        var isMessage: Bool {
            if case .message = self {
                return true
            }
            
            return false
        }
        
        var isAttachment: Bool {
            if case .attachment = self {
                return true
            }
            
            return false
        }
    }
    
    /// A list of a custom extra data type.
    public static var decodableTypes: [DecodableType] = []
    
    /// An extra data.
    public let data: Codable
    
    /// Init an extra data with custom data.
    ///
    /// - Parameter encodableData: an extra data for encoding.
    public init(_ encodableData: Codable) {
        data = encodableData
    }
    
    public func encode(to encoder: Encoder) throws {
        try data.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        data = EmptyData()
    }
}

// MARK: - Safe Helpers

extension ExtraData {
    
    func encodeSafely(to encoder: Encoder) {
        do {
            try encode(to: encoder)
        } catch {
            ClientLogger.log("🧳", error, message: "⚠️🎩 when encoding an extra data: \(encoder)")
        }
    }
    
    static func decode(from decoder: Decoder, _ decodableType: DecodableType?) -> ExtraData? {
        guard let decodableType = decodableType else {
            return nil
        }
        
        let extraDataType: Codable.Type
        
        switch decodableType {
        case .channel(let codableType), .message(let codableType), .attachment(let codableType):
            extraDataType = codableType
        }
        
        do {
            return try ExtraData(extraDataType.init(from: decoder))
        } catch {
            ClientLogger.log("🧳", error, message: "⚠️🎩 failed decoding extra data: \(extraDataType)")
        }
        
        return nil
    }
}
