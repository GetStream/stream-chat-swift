//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension TranslationLanguage {
    public var languageCode: String { rawValue }

    public convenience init(languageCode: String) {
        self.init(rawValue: languageCode)
    }
}

// Descriptive aliases for the generated language codes. Deprecated with
// @available(*, deprecated, renamed:) in v6.
public extension TranslationLanguage {
    static var afrikaans: TranslationLanguage { af }
    static var albanian: TranslationLanguage { sq }
    static var amharic: TranslationLanguage { am }
    static var arabic: TranslationLanguage { ar }
    static var azerbaijani: TranslationLanguage { az }
    static var bengali: TranslationLanguage { bn }
    static var bosnian: TranslationLanguage { bs }
    static var bulgarian: TranslationLanguage { bg }
    static var chineseSimplified: TranslationLanguage { zh }
    static var chineseTraditional: TranslationLanguage { zhTW }
    static var croatian: TranslationLanguage { hr }
    static var czech: TranslationLanguage { cs }
    static var danish: TranslationLanguage { da }
    static var dari: TranslationLanguage { faAF }
    static var dutch: TranslationLanguage { nl }
    static var english: TranslationLanguage { en }
    static var estonian: TranslationLanguage { et }
    static var finnish: TranslationLanguage { fi }
    static var french: TranslationLanguage { fr }
    static var frenchCanada: TranslationLanguage { frCA }
    static var georgian: TranslationLanguage { ka }
    static var german: TranslationLanguage { de }
    static var greek: TranslationLanguage { el }
    static var hausa: TranslationLanguage { ha }
    static var haitianCreole: TranslationLanguage { ht }
    static var hebrew: TranslationLanguage { he }
    static var hindi: TranslationLanguage { hi }
    static var hungarian: TranslationLanguage { hu }
    static var indonesian: TranslationLanguage { id }
    static var italian: TranslationLanguage { it }
    static var japanese: TranslationLanguage { ja }
    static var korean: TranslationLanguage { ko }
    static var latvian: TranslationLanguage { lv }
    static var lithuanian: TranslationLanguage { lt }
    static var malay: TranslationLanguage { ms }
    static var norwegian: TranslationLanguage { no }
    static var persian: TranslationLanguage { fa }
    static var pashto: TranslationLanguage { ps }
    static var polish: TranslationLanguage { pl }
    static var portuguese: TranslationLanguage { pt }
    static var romanian: TranslationLanguage { ro }
    static var russian: TranslationLanguage { ru }
    static var serbian: TranslationLanguage { sr }
    static var slovak: TranslationLanguage { sk }
    static var slovenian: TranslationLanguage { sl }
    static var somali: TranslationLanguage { so }
    static var spanish: TranslationLanguage { es }
    static var spanishMexico: TranslationLanguage { esMX }
    static var swahili: TranslationLanguage { sw }
    static var swedish: TranslationLanguage { sv }
    static var tagalog: TranslationLanguage { tl }
    static var tamil: TranslationLanguage { ta }
    static var thai: TranslationLanguage { th }
    static var turkish: TranslationLanguage { tr }
    static var ukrainian: TranslationLanguage { uk }
    static var urdu: TranslationLanguage { ur }
    static var vietnamese: TranslationLanguage { vi }

    static let allCases: [TranslationLanguage] = [
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
        .haitianCreole,
        .hebrew,
        .hindi,
        .hungarian,
        .indonesian,
        .italian,
        .japanese,
        .korean,
        .latvian,
        .lithuanian,
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

extension TranslationLanguage {
    static func languages(fromCommaSeparated value: String?) -> Set<TranslationLanguage> {
        guard let value = value?.trimmingCharacters(in: .whitespaces), !value.isEmpty else { return [] }
        return Set(
            value
                .components(separatedBy: ",")
                .map { TranslationLanguage(languageCode: $0.trimmingCharacters(in: .whitespaces)) }
        )
    }
}
