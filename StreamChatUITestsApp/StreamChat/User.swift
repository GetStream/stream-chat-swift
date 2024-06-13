//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension UserCredentials {

    static var `default`: UserCredentials {
        ProcessInfo.processInfo.arguments.contains("SWIFTUI_API_KEY") ? .swiftUI : .swift
    }

    static var swift: UserCredentials {
        UserCredentials(id: "luke_skywalker",
                        name: "Luke Skywalker",
                        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!,
                        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0",
                        birthLand: "Tatooine")
    }
    
    static var swiftUI: UserCredentials {
        UserCredentials(id: "luke_skywalker",
                        name: "Luke Skywalker",
                        avatarURL: URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!,
                        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.b6EiC8dq2AHk0JPfI-6PN-AM9TVzt8JV-qB1N9kchlI",
                        birthLand: "Tatooine")
    }
}
