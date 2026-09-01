//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class TranslationLanguage: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let af = TranslationLanguage(rawValue: "af")
    public static let am = TranslationLanguage(rawValue: "am")
    public static let ar = TranslationLanguage(rawValue: "ar")
    public static let az = TranslationLanguage(rawValue: "az")
    public static let bg = TranslationLanguage(rawValue: "bg")
    public static let bn = TranslationLanguage(rawValue: "bn")
    public static let bs = TranslationLanguage(rawValue: "bs")
    public static let cs = TranslationLanguage(rawValue: "cs")
    public static let da = TranslationLanguage(rawValue: "da")
    public static let de = TranslationLanguage(rawValue: "de")
    public static let el = TranslationLanguage(rawValue: "el")
    public static let en = TranslationLanguage(rawValue: "en")
    public static let es = TranslationLanguage(rawValue: "es")
    public static let esMX = TranslationLanguage(rawValue: "es-MX")
    public static let et = TranslationLanguage(rawValue: "et")
    public static let fa = TranslationLanguage(rawValue: "fa")
    public static let faAF = TranslationLanguage(rawValue: "fa-AF")
    public static let fi = TranslationLanguage(rawValue: "fi")
    public static let fr = TranslationLanguage(rawValue: "fr")
    public static let frCA = TranslationLanguage(rawValue: "fr-CA")
    public static let ha = TranslationLanguage(rawValue: "ha")
    public static let he = TranslationLanguage(rawValue: "he")
    public static let hi = TranslationLanguage(rawValue: "hi")
    public static let hr = TranslationLanguage(rawValue: "hr")
    public static let ht = TranslationLanguage(rawValue: "ht")
    public static let hu = TranslationLanguage(rawValue: "hu")
    public static let id = TranslationLanguage(rawValue: "id")
    public static let it = TranslationLanguage(rawValue: "it")
    public static let ja = TranslationLanguage(rawValue: "ja")
    public static let ka = TranslationLanguage(rawValue: "ka")
    public static let ko = TranslationLanguage(rawValue: "ko")
    public static let lt = TranslationLanguage(rawValue: "lt")
    public static let lv = TranslationLanguage(rawValue: "lv")
    public static let ms = TranslationLanguage(rawValue: "ms")
    public static let nl = TranslationLanguage(rawValue: "nl")
    public static let no = TranslationLanguage(rawValue: "no")
    public static let pl = TranslationLanguage(rawValue: "pl")
    public static let ps = TranslationLanguage(rawValue: "ps")
    public static let pt = TranslationLanguage(rawValue: "pt")
    public static let ro = TranslationLanguage(rawValue: "ro")
    public static let ru = TranslationLanguage(rawValue: "ru")
    public static let sk = TranslationLanguage(rawValue: "sk")
    public static let sl = TranslationLanguage(rawValue: "sl")
    public static let so = TranslationLanguage(rawValue: "so")
    public static let sq = TranslationLanguage(rawValue: "sq")
    public static let sr = TranslationLanguage(rawValue: "sr")
    public static let sv = TranslationLanguage(rawValue: "sv")
    public static let sw = TranslationLanguage(rawValue: "sw")
    public static let ta = TranslationLanguage(rawValue: "ta")
    public static let th = TranslationLanguage(rawValue: "th")
    public static let tl = TranslationLanguage(rawValue: "tl")
    public static let tr = TranslationLanguage(rawValue: "tr")
    public static let uk = TranslationLanguage(rawValue: "uk")
    public static let ur = TranslationLanguage(rawValue: "ur")
    public static let vi = TranslationLanguage(rawValue: "vi")
    public static let zh = TranslationLanguage(rawValue: "zh")
    public static let zhTW = TranslationLanguage(rawValue: "zh-TW")
}

final class TranslateMessageRequest: Sendable, Encodable, JSONEncodable {
    /// Language to translate message to
    let language: TranslationLanguage

    init(language: TranslationLanguage) {
        self.language = language
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case language
    }
}
