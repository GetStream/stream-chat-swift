//
//  Language.swift
//  StreamChatClient
//
//  Created by Bahadir Oncel on 15.06.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public enum Language: Hashable {
    case afrikaans
    case albanian
    case amharic
    case arabic
    case azerbaijani
    case bengali
    case bosnian
    case bulgarian
    case chineseSimplified
    case chineseTraditional
    case croatian
    case czech
    case danish
    case dari
    case dutch
    case english
    case estonian
    case finnish
    case french
    case frenchCanada
    case georgian
    case german
    case greek
    case hausa
    case hebrew
    case hindi
    case hungarian
    case indonesian
    case italian
    case japanese
    case korean
    case latvian
    case malay
    case norwegian
    case persian
    case pashto
    case polish
    case portuguese
    case romanian
    case russian
    case serbian
    case slovak
    case slovenian
    case somali
    case spanish
    case spanishMexico
    case swahili
    case swedish
    case tagalog
    case tamil
    case thai
    case turkish
    case ukrainian
    case urdu
    case vietnamese
    case custom(String)
    
    var languageCode: String {
        switch self {
        case .afrikaans:
            return "af"
        case .albanian:
            return "sq"
        case .amharic:
            return "am"
        case .arabic:
            return "ar"
        case .azerbaijani:
            return "az"
        case .bengali:
            return "bn"
        case .bosnian:
            return "bs"
        case .bulgarian:
            return "bg"
        case .chineseSimplified:
            return "zh"
        case .chineseTraditional:
            return "zh-TW"
        case .croatian:
            return "hr"
        case .czech:
            return "cs"
        case .danish:
            return "da"
        case .dari:
            return "fa-AF"
        case .dutch:
            return "nl"
        case .english:
            return "en"
        case .estonian:
            return "et"
        case .finnish:
            return "fi"
        case .french:
            return "fr"
        case .frenchCanada:
            return "fr-CA"
        case .georgian:
            return "ka"
        case .german:
            return "de"
        case .greek:
            return "el"
        case .hausa:
            return "ha"
        case .hebrew:
            return "he"
        case .hindi:
            return "hi"
        case .hungarian:
            return "hu"
        case .indonesian:
            return "id"
        case .italian:
            return "it"
        case .japanese:
            return "ja"
        case .korean:
            return "ko"
        case .latvian:
            return "lv"
        case .malay:
            return "ms"
        case .norwegian:
            return "no"
        case .persian:
            return "fa"
        case .pashto:
            return "ps"
        case .polish:
            return "pl"
        case .portuguese:
            return "pt"
        case .romanian:
            return "ro"
        case .russian:
            return "ru"
        case .serbian:
            return "sr"
        case .slovak:
            return "sk"
        case .slovenian:
            return "sl"
        case .somali:
            return "so"
        case .spanish:
            return "es"
        case .spanishMexico:
            return "es-MX"
        case .swahili:
            return "sw"
        case .swedish:
            return "sv"
        case .tagalog:
            return "tl"
        case .tamil:
            return "ta"
        case .thai:
            return "th"
        case .turkish:
            return "tr"
        case .ukrainian:
            return "uk"
        case .urdu:
            return "ur"
        case .vietnamese:
            return "vi"
        case let .custom(languageCode):
            return languageCode
        }
    }

    init?(locale: Locale) {
        guard let languageCode = locale.languageCode else { return nil }
        let regionCode = locale.regionCode ?? ""
        let fullLanguageCode = languageCode + (regionCode.isEmpty ? "" : "-\(regionCode)")
        
        guard let language = Language.allCases.first(where: { $0.languageCode == fullLanguageCode }) else {
            return nil
        }
        
        self = language
    }
    
    /// Compiler cannot synthesize it since `.custom` has associated value
    static var allCases: [Language] = [.afrikaans, .albanian, .amharic, .arabic, .azerbaijani,
                                       .bengali, .bosnian, .bulgarian, .chineseSimplified, .chineseTraditional,
                                       .croatian, .czech, .danish, .dari, .dutch,
                                       .english, .estonian, .finnish, .french, .frenchCanada,
                                       .georgian, .german, .greek, .hausa, .hebrew,
                                       .hindi, .hungarian, .indonesian, .italian, .japanese,
                                       .korean, .latvian, .malay, .norwegian, .persian,
                                       .pashto, .polish, .portuguese, .romanian, .russian,
                                       .serbian, .slovak, .slovenian, .somali, .spanish,
                                       .spanishMexico, .swahili, .swedish, .tagalog, .tamil,
                                       .thai, .turkish, .ukrainian, .urdu, .vietnamese]
}
