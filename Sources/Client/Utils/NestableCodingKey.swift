//
//  NestableCodingKey.swift
//  StreamChatClient
//
//  Created by Bahadir Oncel on 1.04.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//
// Courtesy of AliSoftware
// https://gist.github.com/AliSoftware/89b275d7259d23ebf12d377b6ffe15cd

import Foundation

/// Use this to annotate the properties that require a depth traversal during decoding.
/// The corresponding `CodingKey` for this property must be a `NestableCodingKey`
@propertyWrapper
public struct NestedKey<T: Decodable>: Decodable {
    struct AnyCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int?
        
        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
    
    public let wrappedValue: T?
    
    public init(from decoder: Decoder) throws {
        guard let key = decoder.codingPath.last else {
            throw DecodingError.valueNotFound(CodingKey.self,
                                              DecodingError.Context(codingPath: decoder.codingPath,
                                                                    debugDescription: "No CodingKey found in codingPath"))
        }
        
        guard let nestedKey = key as? NestableCodingKey else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: decoder.codingPath,
                                                                  debugDescription: "Key \(key) is not a NestableCodingKey"))
        }
        
        let nextKeys = nestedKey.path.dropFirst()
        
        // key descent
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let lastLeaf = try nextKeys.indices.dropLast().reduce(container) { (nestedContainer, keyIdx) in
            do {
                return try nestedContainer.nestedContainer(keyedBy: AnyCodingKey.self,
                                                           forKey: AnyCodingKey(stringValue: nextKeys[keyIdx]))
            } catch DecodingError.keyNotFound(let key, let ctx) {
                throw NestedKey.keyNotFoundError(key: key, ctx: ctx, container: container, nextKeys: nextKeys[..<keyIdx])
            }
        }
        
        // key leaf
        guard let lastKey = nextKeys.last else {
            throw DecodingError.valueNotFound(NestableCodingKey.self,
                                              DecodingError.Context(codingPath: decoder.codingPath,
                                                                    debugDescription: "NestableCodingKey must be composed of a path"))
        }
        
        do {
            wrappedValue = try lastLeaf.decode(T.self, forKey: AnyCodingKey(stringValue: lastKey))
        } catch {
            wrappedValue = nil
        }
    }
    
    private static func keyNotFoundError<C: Collection>(key: CodingKey,
                                                        ctx: DecodingError.Context,
                                                        container: KeyedDecodingContainer<AnyCodingKey>,
                                                        nextKeys: C) -> DecodingError
        where C.Element == String {
            DecodingError.keyNotFound(key, DecodingError.Context(
                codingPath: container.codingPath + nextKeys.map(AnyCodingKey.init(stringValue:)),
                debugDescription: "NestedKey: No value associated with key \"\(key.stringValue)\"",
                underlyingError: ctx.underlyingError
            ))
    }
}

/// Use this instead of `CodingKey` to annotate your `enum CodingKeys: String, NestableCodingKey`.
/// Use a `/` to separate the components of the path to nested keys
protocol NestableCodingKey: CodingKey {
    var path: [String] { get }
}

extension NestableCodingKey where Self: RawRepresentable, Self.RawValue == String {
    var stringValue: String {
        path.first ?? ""
    }
    
    var path: [String] {
        self.rawValue.components(separatedBy: "/")
    }
    
    init?(stringValue: String) {
        self.init(rawValue: stringValue)
    }
}
