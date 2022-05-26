//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public let apiKeyString = "8br4watad788"
public let applicationGroupIdentifier = "group.io.getstream.iOS.ChatDemoApp"
public let currentUserIdRegisteredForPush = "currentUserIdRegisteredForPush"

enum DemoUserType {
    case credentials(UserCredentials)
    case anonymous
    case guest(String)
}

public struct UserCredentials {
    let id: String
    let name: String
    let avatarURL: URL
    let token: String
    let birthLand: String
}

public extension UserCredentials {
    var userInfo: UserInfo {
        .init(
            id: id,
            name: name,
            imageURL: avatarURL,
            extraData: [ChatUser.birthLandFieldName: .string(birthLand)]
        )
    }
    
    static func builtInUsersByID(id: String) -> UserCredentials? {
        builtInUsers.first { $0.id == id }
    }

    static let builtInUsers: [UserCredentials] = [
        (
            "luke_skywalker",
            "Luke Skywalker",
            "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIiLCJleHAiOjE2NTM0OTE2NjR9.0o-eLePnOnCdHv072wSPnt7V7nM-v173krID2BTFwTM",
            "Tatooine"
        ),
        (
            "leia_organa",
            "Leia Organa",
            "https://vignette.wikia.nocookie.net/starwars/images/f/fc/Leia_Organa_TLJ.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGVpYV9vcmdhbmEifQ.IzwBuaYwX5dRvnDDnJN2AyW3wwfYwgQm3w-1RD4BLPU",
            "Polis Massa"
        ),
        (
            "han_solo",
            "Han Solo",
            "https://vignette.wikia.nocookie.net/starwars/images/e/e2/TFAHanSolo.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiaGFuX3NvbG8ifQ.R6PkQeGPcusALmhvaST50lwroL_JkZnI3Q7hQ1Hvj3k",
            "Corellia"
        ),
        (
            "lando_calrissian",
            "Lando Calrissian",
            "https://vignette.wikia.nocookie.net/starwars/images/8/8f/Lando_ROTJ.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGFuZG9fY2Fscmlzc2lhbiJ9.n_K7d-FroQzBUxETNcEQYqiW_U9CPjRHZHT1hyAjlAQ",
            "Socorro"
        ),
        (
            "chewbacca",
            "Chewbacca",
            "https://vignette.wikia.nocookie.net/starwars/images/4/48/Chewbacca_TLJ.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2hld2JhY2NhIn0.4nNFfO0dehvdLxDUGaMQPpMliSTGjHqh1C2Zo8wyaeM",
            "Kashyyyk"
        ),
        (
            "c-3po",
            "C-3PO",
            "https://vignette.wikia.nocookie.net/starwars/images/3/3f/C-3PO_TLJ_Card_Trader_Award_Card.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYy0zcG8ifQ.J4Xzu8rKP1XWQvSNV6wzWKW403qKd5N3FalpWXTDauw",
            "Affa"
        ),
        (
            "r2-d2",
            "R2-D2",
            "https://vignette.wikia.nocookie.net/starwars/images/e/eb/ArtooTFA2-Fathead.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicjItZDIifQ.UpSEW8jA2tYsUTPKbdFGMtHHnu9_AnEQqTK6TdT8L1g",
            "Naboo"
        ),
        (
            "anakin_skywalker",
            "Anakin Skywalker",
            "https://vignette.wikia.nocookie.net/starwars/images/6/6f/Anakin_Skywalker_RotS.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYW5ha2luX3NreXdhbGtlciJ9.oJkwakjdqw6gCA3-kaUaKqSVEcWO5ob5DJuyJCtnT6U",
            "Tatooine"
        ),
        (
            "obi-wan_kenobi",
            "Obi-Wan Kenobi",
            "https://vignette.wikia.nocookie.net/starwars/images/4/4e/ObiWanHS-SWE.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoib2JpLXdhbl9rZW5vYmkifQ.AVOtnXtMq9crXFwl68BrBRob335phYpYfPPq5i2agUM",
            "Stewjon"
        ),
        (
            "padme_amidala",
            "Padmé Amidala",
            "https://vignette.wikia.nocookie.net/starwars/images/b/b2/Padmegreenscrshot.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicGFkbWVfYW1pZGFsYSJ9.X8CwsnrWKvdrS6XchcUMZDLh_W0X4Gpx-oNyjGAdenI",
            "Naboo"
        ),
        (
            "qui-gon_jinn",
            "Qui-Gon Jinn",
            "https://vignette.wikia.nocookie.net/starwars/images/f/f6/Qui-Gon_Jinn_Headshot_TPM.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicXVpLWdvbl9qaW5uIn0.EDuyuTkyzG1OA3ROwa3sK8-K_U2MGREsY4Ic7flXvzw",
            "Coruscant"
        ),
        (
            "mace_windu",
            "Mace Windu",
            "https://vignette.wikia.nocookie.net/starwars/images/5/58/Mace_ROTS.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFjZV93aW5kdSJ9.x8xFcOQFr0XUDeA3BH0ISsR2VSmWSxmMgbnz8lprV58",
            "Haruun Kal"
        ),
        (
            "jar_jar_binks",
            "Jar Jar Binks",
            "https://vignette.wikia.nocookie.net/starwars/images/d/d2/Jar_Jar_aotc.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiamFyX2phcl9iaW5rcyJ9.5-GhGE8sqlxKNUMyBGovrkoaxgkEQAUMJ3CZfcxyrZg",
            "Naboo"
        ),
        (
            "darth_maul",
            "Darth Maul",
            "https://vignette.wikia.nocookie.net/starwars/images/5/50/Darth_Maul_profile.png",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGFydGhfbWF1bCJ9._cbBA2ThWpXcyxwvBV6gvqAwnw0lvzfHAlZ4stGqf2o",
            "Dathomir"
        ),
        (
            "count_dooku",
            "Count Dooku",
            "https://vignette.wikia.nocookie.net/starwars/images/b/b8/Dooku_Headshot.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY291bnRfZG9va3UifQ.0sN_cPTKrXsxC23WUSIBUQK5IUZsdGijmqY50HJERQw",
            "Serenno"
        ),
        (
            "general_grievous",
            "General Grievous",
            "https://vignette.wikia.nocookie.net/starwars/images/d/de/Grievoushead.jpg",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZ2VuZXJhbF9ncmlldm91cyJ9.FPRvRoeZdALErBA1bDybch4xY-c5CEinuc9qqEPzX4E",
            "Qymaen jai Sheelal"
        )

    ].map {
        UserCredentials(id: $0.0, name: $0.1, avatarURL: URL(string: $0.2)!, token: $0.3, birthLand: $0.4)
    }
}
