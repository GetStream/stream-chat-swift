//
//  LocalizedMessage.swift
//  StreamChatClient
//
//  Created by Bahadir Oncel on 15.06.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageTranslations: Decodable {
    private static let translatedSuffix = "_text"
    
    private struct CodingKeys: CodingKey, Hashable {
        var stringValue: String
        
        init(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            return  nil
        }
        
        static let originalLanguage = CodingKeys(stringValue: "language")
        
        static func translated(to language: Language) -> CodingKeys {
            CodingKeys(stringValue: language.languageCode + translatedSuffix)
        }
    }
    
    public let originalLanguage: String
    public let translated: [Language: String]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        originalLanguage = try container.decode(String.self, forKey: .originalLanguage)
        
        var translated = [Language: String]()
        
        for language in Language.allCases {
            if let translatedText = try container.decodeIfPresent(String.self, forKey: .translated(to: language)) {
                translated[language] = translatedText
            }
        }
        
        // If the user passed a custom language via `Language.custom`
        let allKnownKeys = Set(Language.allCases.map(CodingKeys.translated)) + [CodingKeys.originalLanguage]
        let unknownKeys = Set(container.allKeys).subtracting(allKnownKeys)
        for key in unknownKeys {
            let keyString = key.stringValue
            guard let suffixRange = keyString.range(of: MessageTranslations.translatedSuffix) else {
                ClientLogger.log("❌", level: .error, "Unknown key in `translate` response: \(keyString), cannot decode")
                continue
            }
            let unknownLanguageCode = String(keyString.prefix(upTo: suffixRange.lowerBound))
            let translatedText = try container.decode(String.self, forKey: key)
            translated[.custom(unknownLanguageCode)] = translatedText
        }
        
        self.translated = translated
    }
}
