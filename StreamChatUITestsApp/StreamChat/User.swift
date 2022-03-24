//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

let apiKey = "8br4watad788"
let applicationGroupIdentifier = "group.io.getstream.iOS.StreamChatUITestsApp"

struct UserCredentials {
    let id: String
    let name: String
    let avatarURL: URL
    let token: Token
    let birthLand: String
}

extension UserCredentials {
    
    static var `default`: UserCredentials {
        UserCredentials(id: "luke_skywalker",
                        name: "Luke Skywalker",
                        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!,
                        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0",
                        birthLand: "Tatooine")
    }
}
