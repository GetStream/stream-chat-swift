//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

let apiKeyString = ProcessInfo.processInfo.environment["CUSTOM_API_KEY"] ?? DemoApiKeys.frankfurtC1
let applicationGroupIdentifier = "group.io.getstream.iOS.ChatDemoApp"

enum DemoUserType {
    case credentials(UserCredentials)
    case anonymous
    case guest(String)
}

struct UserCredentials {
    let id: String
    let name: String
    let avatarURL: URL
    let token: Token
    let birthLand: String

    var userInfo: UserInfo {
        .init(
            id: id,
            name: name,
            imageURL: avatarURL,
            extraData: [ChatUser.birthLandFieldName: .string(birthLand)]
        )
    }
}

// MARK: - Built-in users

extension UserCredentials {
    static let builtInUsers: [UserCredentials] = [
        .luke,
        .leia,
        .hanSolo,
        .lando,
        .chewbacca,
        .c3po,
        .r2d2,
        .anakin,
        .obiwan,
        .padme,
        .quiGonJinn,
        .maceWindu,
        .jarJarBinks,
        .darthMaul,
        .countDooku,
        .generalGrievous
    ]

    static func builtInUsersByID(id: String) -> UserCredentials? {
        builtInUsers.first { $0.id == id }
    }

    static let luke = Self(
        id: "luke_skywalker",
        name: "Luke Skywalker",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!,
        token: DemoUserTokens.luke,
        birthLand: "Tatooine"
    )

    static let leia = Self(
        id: "leia_organa",
        name: "Leia Organa",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png")!,
        token: DemoUserTokens.leia,
        birthLand: "Polis Massa"
    )

    static let hanSolo = Self(
        id: "han_solo",
        name: "Han Solo",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/e/e2/TFAHanSolo.png")!,
        token: DemoUserTokens.hanSolo,
        birthLand: "Corellia"
    )

    static let lando = Self(
        id: "lando_calrissian",
        name: "Lando Calrissian",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/8/8f/Lando_ROTJ.png")!,
        token: DemoUserTokens.lando,
        birthLand: "Socorro"
    )

    static let chewbacca = Self(
        id: "chewbacca",
        name: "Chewbacca",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/4/48/Chewbacca_TLJ.png")!,
        token: DemoUserTokens.chewbacca,
        birthLand: "Kashyyyk"
    )

    static let c3po = Self(
        id: "c-3po",
        name: "C-3PO",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/3/3f/C-3PO_TLJ_Card_Trader_Award_Card.png")!,
        token: DemoUserTokens.c3po,
        birthLand: "Affa"
    )

    static let r2d2 = Self(
        id: "r2-d2",
        name: "R2-D2",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/e/eb/ArtooTFA2-Fathead.png")!,
        token: DemoUserTokens.r2d2,
        birthLand: "Naboo"
    )

    static let anakin = Self(
        id: "anakin_skywalker",
        name: "Anakin Skywalker",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/6/6f/Anakin_Skywalker_RotS.png")!,
        token: DemoUserTokens.anakin,
        birthLand: "Tatooine"
    )

    static let obiwan = Self(
        id: "obi-wan_kenobi",
        name: "Obi-Wan Kenobi",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/4/4e/ObiWanHS-SWE.jpg")!,
        token: DemoUserTokens.obiwan,
        birthLand: "Stewjon"
    )

    static let padme = Self(
        id: "padme_amidala",
        name: "Padmé Amidala",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/b/b2/Padmegreenscrshot.jpg")!,
        token: DemoUserTokens.padme,
        birthLand: "Naboo"
    )

    static let quiGonJinn = Self(
        id: "qui-gon_jinn",
        name: "Qui-Gon Jinn",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/f/f6/Qui-Gon_Jinn_Headshot_TPM.jpg")!,
        token: DemoUserTokens.quiGonJinn,
        birthLand: "Coruscant"
    )

    static let maceWindu = Self(
        id: "mace_windu",
        name: "Mace Windu",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/5/58/Mace_ROTS.png")!,
        token: DemoUserTokens.maceWindu,
        birthLand: "Haruun Kal"
    )

    static let jarJarBinks = Self(
        id: "jar_jar_binks",
        name: "Jar Jar Binks",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/d/d2/Jar_Jar_aotc.jpg")!,
        token: DemoUserTokens.jarJarBinks,
        birthLand: "Naboo"
    )

    static let darthMaul = Self(
        id: "darth_maul",
        name: "Darth Maul",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/5/50/Darth_Maul_profile.png")!,
        token: DemoUserTokens.darthMaul,
        birthLand: "Dathomir"
    )

    static let countDooku = Self(
        id: "count_dooku",
        name: "Count Dooku",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/b/b8/Dooku_Headshot.jpg")!,
        token: DemoUserTokens.countDooku,
        birthLand: "Serenno"
    )

    static let generalGrievous = Self(
        id: "general_grievous",
        name: "General Grievous",
        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/d/de/Grievoushead.jpg")!,
        token: DemoUserTokens.generalGrievous,
        birthLand: "Qymaen jai Sheelal"
    )
}

// MARK: - Tokens for different Api Keys

enum DemoApiKeys {
    static let frankfurtC1 = "8br4watad788" // UIKit default
    static let frankfurtC2 = "pd67s34fzpgw"
    static let usEastC6 = "zcgvnykxsfm8" // SwiftUI default
}

enum DemoUserTokens {
    static var luke: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.hZ59SWtp_zLKVV9ShkqkTsCGi_jdPHly7XNCf5T_Ev0"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.b6EiC8dq2AHk0JPfI-6PN-AM9TVzt8JV-qB1N9kchlI"
        default:
            ""
        }
    }
    
    static var leia: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGVpYV9vcmdhbmEifQ.IzwBuaYwX5dRvnDDnJN2AyW3wwfYwgQm3w-1RD4BLPU"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGVpYV9vcmdhbmEifQ.8NXs4DZrx_hljsaC8d6xlZ07FUgenKmb6hDNU-KFQ3M"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGVpYV9vcmdhbmEifQ.Z5jwZggIKuspn1Z76MJHF9AY_VdAFg_jnTS6CP5ZZN0"
        default:
            ""
        }
    }
    
    static var hanSolo: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiaGFuX3NvbG8ifQ.R6PkQeGPcusALmhvaST50lwroL_JkZnI3Q7hQ1Hvj3k"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiaGFuX3NvbG8ifQ.lLYA_RUGZlmWULg-En-7tbTAuoVWFSR1-ad_e7s8PqM"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiaGFuX3NvbG8ifQ.b5lfc4dHWbfxKFF_NdEGd9K25U6ywSp5ImBW_ncO3OA"
        default:
            ""
        }
    }
    
    static var lando: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGFuZG9fY2Fscmlzc2lhbiJ9.n_K7d-FroQzBUxETNcEQYqiW_U9CPjRHZHT1hyAjlAQ"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGFuZG9fY2Fscmlzc2lhbiJ9.QIxUC5nTo3x1C4bkyEv5b8-pHZwIE5BDeRuBw4Z1K14"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGFuZG9fY2Fscmlzc2lhbiJ9.jtR-LRHNSLhPJLlrNOMWa4VF5ublU-vySD9efv-8o8g"
        default:
            ""
        }
    }
    
    static var chewbacca: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2hld2JhY2NhIn0.4nNFfO0dehvdLxDUGaMQPpMliSTGjHqh1C2Zo8wyaeM"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2hld2JhY2NhIn0.4FJLy1za8OWCS8Bf6fW76w_TGfvJ0Q8o60gLk0qtrnc"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2hld2JhY2NhIn0.GVzFcua20gVefzmEMlEX-dJXX56Dyoza3Vfkqin1yTc"
        default:
            ""
        }
    }
    
    static var c3po: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYy0zcG8ifQ.J4Xzu8rKP1XWQvSNV6wzWKW403qKd5N3FalpWXTDauw"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYy0zcG8ifQ.CHaRSL3UfqDjUbp-W3VCxcTbD40YzdNKt_X7of9e5hY"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYy0zcG8ifQ._3IfTtUJTexVfCOt9mL22mLeAogaOXPR-5d3kq_h8cs"
        default:
            ""
        }
    }
    
    static var r2d2: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicjItZDIifQ.UpSEW8jA2tYsUTPKbdFGMtHHnu9_AnEQqTK6TdT8L1g"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicjItZDIifQ.eew9OeGYjpyYY44s0R5PyMAy5mwlyUYnKJRDPccV2hM"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicjItZDIifQ.zoi2pzALI8a2sQFLhOIxnZawHooj_PqJF0jToqOpNP4"
        default:
            ""
        }
    }
    
    static var anakin: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYW5ha2luX3NreXdhbGtlciJ9.oJkwakjdqw6gCA3-kaUaKqSVEcWO5ob5DJuyJCtnT6U"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYW5ha2luX3NreXdhbGtlciJ9.4Rsce_GZeY9g4SHAVgqkjgqAHl70_8iSHCAYeRSuMY8"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYW5ha2luX3NreXdhbGtlciJ9.ZwCV1qPrSAsie7-0n61JQrSEDbp6fcMgVh4V2CB0kM8"
        default:
            ""
        }
    }
    
    static var obiwan: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoib2JpLXdhbl9rZW5vYmkifQ.AVOtnXtMq9crXFwl68BrBRob335phYpYfPPq5i2agUM"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoib2JpLXdhbl9rZW5vYmkifQ.837rrq4z5caoA_xIiTVo7lRGj0hK3NxpBZ-gXPLkjvY"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoib2JpLXdhbl9rZW5vYmkifQ.PU1vMfuhVi7gpfk3TBwM9KmtVldEtsFER8OElLfzFig"
        default:
            ""
        }
    }
    
    static var padme: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicGFkbWVfYW1pZGFsYSJ9.X8CwsnrWKvdrS6XchcUMZDLh_W0X4Gpx-oNyjGAdenI"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicGFkbWVfYW1pZGFsYSJ9.4czOc0NE73usN7eSUoWzg6-_sw5BhahE_QRMC-minHc"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicGFkbWVfYW1pZGFsYSJ9.qT6nK_5eys8GRK-G_rCD-u58UBq245umMTmE2nVtgm0"
        default:
            ""
        }
    }
    
    static var quiGonJinn: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicXVpLWdvbl9qaW5uIn0.EDuyuTkyzG1OA3ROwa3sK8-K_U2MGREsY4Ic7flXvzw"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicXVpLWdvbl9qaW5uIn0.P4Dwkdze9u_fcz8LtDb8ngroYVDKjT0eZoRoIsDB0oA"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicXVpLWdvbl9qaW5uIn0.HvKHNYXUdlay07mUZvsSFdQYi_3SXPr_kxYaaiEr278"
        default:
            ""
        }
    }
    
    static var maceWindu: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFjZV93aW5kdSJ9.x8xFcOQFr0XUDeA3BH0ISsR2VSmWSxmMgbnz8lprV58"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFjZV93aW5kdSJ9.YzF0Nw8A-2lLgce-eVn6FCH1E2qZ_iSHECoaRJwXpPk"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFjZV93aW5kdSJ9.K6dE1tos0X1bKoehbRQ6DedQcMJf5ZOGY_n9aEioU7A"
        default:
            ""
        }
    }
    
    static var jarJarBinks: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiamFyX2phcl9iaW5rcyJ9.5-GhGE8sqlxKNUMyBGovrkoaxgkEQAUMJ3CZfcxyrZg"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiamFyX2phcl9iaW5rcyJ9.0Er20q16yB849nTfxmpuk5WwYc7VQWxVQ11jqIzGakk"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiamFyX2phcl9iaW5rcyJ9.wkaMfsuQPlmK1kSPM4f1CVtcVSkZCUL1EMOyp9DT8ns"
        default:
            ""
        }
    }
    
    static var darthMaul: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGFydGhfbWF1bCJ9._cbBA2ThWpXcyxwvBV6gvqAwnw0lvzfHAlZ4stGqf2o"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGFydGhfbWF1bCJ9.xuUrNRTZEIBYHBAJzi4sJVxSIEEii_GF2AQcLMXzg9o"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGFydGhfbWF1bCJ9.eUlDsRbZb5SEd0d8WsjZTzg8SYWOinNf6FiGJHS2Qwg"
        default:
            ""
        }
    }
    
    static var countDooku: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY291bnRfZG9va3UifQ.0sN_cPTKrXsxC23WUSIBUQK5IUZsdGijmqY50HJERQw"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY291bnRfZG9va3UifQ.N3z0edz50FGK7SmCkbNaKBR0DFZdnTwt3mGFrH0WQkQ"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY291bnRfZG9va3UifQ.2RPv-5vrHTAUGOmZUQFeHZ0hyLj-N-34l4s_9edgEfU"
        default:
            ""
        }
    }
    
    static var generalGrievous: Token {
        switch apiKeyString {
        case DemoApiKeys.frankfurtC1:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZ2VuZXJhbF9ncmlldm91cyJ9.FPRvRoeZdALErBA1bDybch4xY-c5CEinuc9qqEPzX4E"
        case DemoApiKeys.frankfurtC2:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZ2VuZXJhbF9ncmlldm91cyJ9.vMoJdWKPt4rsRtcdHiYZxlVkn2jybz5OvpwJnwA5JBk"
        case DemoApiKeys.usEastC6:
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZ2VuZXJhbF9ncmlldm91cyJ9.g2UUZdENuacFIxhYCylBuDJZUZ2x59MTWaSpndWGCTU"
        default:
            ""
        }
    }
}
