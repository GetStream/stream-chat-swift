//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageTranslationsPayload: Decodable {
    private static let translatedSuffix = "_text"
    
    private struct CodingKeys: CodingKey, Hashable {
        var stringValue: String
        
        init(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int?
        
        init?(intValue: Int) {
            nil
        }
        
        static let originalLanguage = CodingKeys(stringValue: "language")
        
        static func translated(to language: TranslationLanguage) -> CodingKeys {
            CodingKeys(stringValue: language.languageCode + translatedSuffix)
        }
    }
    
    public let originalLanguage: String
    public let translated: [TranslationLanguage: String]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        originalLanguage = try container.decode(String.self, forKey: .originalLanguage)
        
        var translated = [TranslationLanguage: String]()
        
        for language in TranslationLanguage.allCases {
            if let translatedText = try container.decodeIfPresent(String.self, forKey: .translated(to: language)) {
                translated[language] = translatedText
            }
        }
        
        // If the user passed a custom language via `Language.custom`
        let allKnownKeys = Set(TranslationLanguage.allCases.map(CodingKeys.translated)) + [CodingKeys.originalLanguage]
        let unknownKeys = Set(container.allKeys).subtracting(allKnownKeys)
        for key in unknownKeys {
            let keyString = key.stringValue
            guard let suffixRange = keyString.range(of: MessageTranslationsPayload.translatedSuffix) else {
                log.warning("Unknown key in `translate` response: \(keyString), cannot decode", subsystems: .httpRequests)
                continue
            }
            let unknownLanguageCode = String(keyString.prefix(upTo: suffixRange.lowerBound))
            let translatedText = try container.decode(String.self, forKey: key)
            translated[.init(languageCode: unknownLanguageCode)] = translatedText
        }
        
        self.translated = translated
    }
}
