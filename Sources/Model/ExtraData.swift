//
//  ExtraData.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 06/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ExtraData: Codable {
    public enum DecodableType {
        case channel(Codable.Type)
        case message(Codable.Type)
        
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
    }
    
    public static var decodableTypes: [DecodableType] = []
    
    public let data: Codable
    
    init(_ encodableData: Codable) {
        data = encodableData
    }
    
    public func encode(to encoder: Encoder) throws {
        try data.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        data = Empty()
    }
}

// MARK: - Safe Helpers

extension ExtraData {
    
    func encodeSafely(to encoder: Encoder) {
        do {
            try encode(to: encoder)
        } catch {
            Client.shared.logger?.log(error, message: "⚠️🎩 ExtraData")
        }
    }
    
    static func decode(from decoder: Decoder, _ decodableType: DecodableType?) -> ExtraData? {
        guard let decodableType = decodableType else {
            return nil
        }
        
        do {
            let extraDataType: Codable.Type
            
            switch decodableType {
            case .channel(let codableType),
                 .message(let codableType):
                extraDataType = codableType
            }
            return try ExtraData(extraDataType.init(from: decoder))
        } catch {
            Client.shared.logger?.log(error, message: "⚠️🎩 ExtraData")
        }
        
        return nil
    }
}
