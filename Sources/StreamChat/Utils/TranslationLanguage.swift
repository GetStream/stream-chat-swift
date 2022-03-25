//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TranslationLanguage: Hashable {
    let languageCode: String
    
    public init(languageCode: String) {
        self.languageCode = languageCode
    }
    
    init?(locale: Locale) {
        guard let languageCode = locale.languageCode else { return nil }
        let regionCode = locale.regionCode ?? ""
        self.init(languageCode: languageCode + (regionCode.isEmpty ? "" : "-\(regionCode)"))
    }
}

public extension TranslationLanguage {
    static let afrikaans: TranslationLanguage = TranslationLanguage(languageCode: "af")
    static let albanian: TranslationLanguage = TranslationLanguage(languageCode: "sq")
    static let amharic: TranslationLanguage = TranslationLanguage(languageCode: "am")
    static let arabic: TranslationLanguage = TranslationLanguage(languageCode: "ar")
    static let azerbaijani: TranslationLanguage = TranslationLanguage(languageCode: "az")
    static let bengali: TranslationLanguage = TranslationLanguage(languageCode: "bn")
    static let bosnian: TranslationLanguage = TranslationLanguage(languageCode: "bs")
    static let bulgarian: TranslationLanguage = TranslationLanguage(languageCode: "bg")
    static let chineseSimplified: TranslationLanguage = TranslationLanguage(languageCode: "zh")
    static let chineseTraditional: TranslationLanguage = TranslationLanguage(languageCode: "zh-TW")
    static let croatian: TranslationLanguage = TranslationLanguage(languageCode: "hr")
    static let czech: TranslationLanguage = TranslationLanguage(languageCode: "cs")
    static let danish: TranslationLanguage = TranslationLanguage(languageCode: "da")
    static let dari: TranslationLanguage = TranslationLanguage(languageCode: "fa-AF")
    static let dutch: TranslationLanguage = TranslationLanguage(languageCode: "nl")
    static let english: TranslationLanguage = TranslationLanguage(languageCode: "en")
    static let estonian: TranslationLanguage = TranslationLanguage(languageCode: "et")
    static let finnish: TranslationLanguage = TranslationLanguage(languageCode: "fi")
    static let french: TranslationLanguage = TranslationLanguage(languageCode: "fr")
    static let frenchCanada: TranslationLanguage = TranslationLanguage(languageCode: "fr-CA")
    static let georgian: TranslationLanguage = TranslationLanguage(languageCode: "ka")
    static let german: TranslationLanguage = TranslationLanguage(languageCode: "de")
    static let greek: TranslationLanguage = TranslationLanguage(languageCode: "el")
    static let hausa: TranslationLanguage = TranslationLanguage(languageCode: "ha")
    static let hebrew: TranslationLanguage = TranslationLanguage(languageCode: "he")
    static let hindi: TranslationLanguage = TranslationLanguage(languageCode: "hi")
    static let hungarian: TranslationLanguage = TranslationLanguage(languageCode: "hu")
    static let indonesian: TranslationLanguage = TranslationLanguage(languageCode: "id")
    static let italian: TranslationLanguage = TranslationLanguage(languageCode: "it")
    static let japanese: TranslationLanguage = TranslationLanguage(languageCode: "ja")
    static let korean: TranslationLanguage = TranslationLanguage(languageCode: "ko")
    static let latvian: TranslationLanguage = TranslationLanguage(languageCode: "lv")
    static let malay: TranslationLanguage = TranslationLanguage(languageCode: "ms")
    static let norwegian: TranslationLanguage = TranslationLanguage(languageCode: "no")
    static let persian: TranslationLanguage = TranslationLanguage(languageCode: "fa")
    static let pashto: TranslationLanguage = TranslationLanguage(languageCode: "ps")
    static let polish: TranslationLanguage = TranslationLanguage(languageCode: "pl")
    static let portuguese: TranslationLanguage = TranslationLanguage(languageCode: "pt")
    static let romanian: TranslationLanguage = TranslationLanguage(languageCode: "ro")
    static let russian: TranslationLanguage = TranslationLanguage(languageCode: "ru")
    static let serbian: TranslationLanguage = TranslationLanguage(languageCode: "sr")
    static let slovak: TranslationLanguage = TranslationLanguage(languageCode: "sk")
    static let slovenian: TranslationLanguage = TranslationLanguage(languageCode: "sl")
    static let somali: TranslationLanguage = TranslationLanguage(languageCode: "so")
    static let spanish: TranslationLanguage = TranslationLanguage(languageCode: "es")
    static let spanishMexico: TranslationLanguage = TranslationLanguage(languageCode: "es-MX")
    static let swahili: TranslationLanguage = TranslationLanguage(languageCode: "sw")
    static let swedish: TranslationLanguage = TranslationLanguage(languageCode: "sv")
    static let tagalog: TranslationLanguage = TranslationLanguage(languageCode: "tl")
    static let tamil: TranslationLanguage = TranslationLanguage(languageCode: "ta")
    static let thai: TranslationLanguage = TranslationLanguage(languageCode: "th")
    static let turkish: TranslationLanguage = TranslationLanguage(languageCode: "tr")
    static let ukrainian: TranslationLanguage = TranslationLanguage(languageCode: "uk")
    static let urdu: TranslationLanguage = TranslationLanguage(languageCode: "ur")
    static let vietnamese: TranslationLanguage = TranslationLanguage(languageCode: "vi")
    
    static var allCases: [Self] = [
        .afrikaans,
        .albanian,
        .amharic,
        .arabic,
        .azerbaijani,
        .bengali,
        .bosnian,
        .bulgarian,
        .chineseSimplified,
        .chineseTraditional,
        .croatian,
        .czech,
        .danish,
        .dari,
        .dutch,
        .english,
        .estonian,
        .finnish,
        .french,
        .frenchCanada,
        .georgian,
        .german,
        .greek,
        .hausa,
        .hebrew,
        .hindi,
        .hungarian,
        .indonesian,
        .italian,
        .japanese,
        .korean,
        .latvian,
        .malay,
        .norwegian,
        .persian,
        .pashto,
        .polish,
        .portuguese,
        .romanian,
        .russian,
        .serbian,
        .slovak,
        .slovenian,
        .somali,
        .spanish,
        .spanishMexico,
        .swahili,
        .swedish,
        .tagalog,
        .tamil,
        .thai,
        .turkish,
        .ukrainian,
        .urdu,
        .vietnamese
    ]
}
