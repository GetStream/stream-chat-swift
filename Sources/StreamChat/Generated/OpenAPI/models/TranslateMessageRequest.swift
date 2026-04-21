//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TranslateMessageRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum TranslateMessageRequestLanguage: String, Sendable, Codable, CaseIterable {
        case af
        case am
        case ar
        case az
        case bg
        case bn
        case bs
        case cs
        case da
        case de
        case el
        case en
        case es
        case esMX = "es-MX"
        case et
        case fa
        case faAF = "fa-AF"
        case fi
        case fr
        case frCA = "fr-CA"
        case ha
        case he
        case hi
        case hr
        case ht
        case hu
        case id
        case it
        case ja
        case ka
        case ko
        case lt
        case lv
        case ms
        case nl
        case no
        case pl
        case ps
        case pt
        case ro
        case ru
        case sk
        case sl
        case so
        case sq
        case sr
        case sv
        case sw
        case ta
        case th
        case tl
        case tr
        case uk
        case ur
        case vi
        case zh
        case zhTW = "zh-TW"
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    /// Language to translate message to
    var language: TranslateMessageRequestLanguage

    init(language: TranslateMessageRequestLanguage) {
        self.language = language
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case language
    }

    static func == (lhs: TranslateMessageRequest, rhs: TranslateMessageRequest) -> Bool {
        lhs.language == rhs.language
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(language)
    }
}
