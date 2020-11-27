//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

let apiKeyString = "q95x9hkbyd6p"

struct UserCredentials {
    let id: String
    let name: String
    let avatarURL: URL
    let token: String
    let apiKey: String
}

extension UserCredentials {
    static let builtInUsers: [UserCredentials] = [
        (
            "cilvia",
            "Neil Hannah",
            "https://ca.slack-edge.com/T02RM6X6B-U01173D1D5J-0dead6eea6ea-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2lsdmlhIn0.jHi2vjKoF02P9lOog0kDVhsIrGFjuWJqZelX5capR30"
        ),
        (
            "jaap",
            "Jaap Baker",
            "https://ca.slack-edge.com/T02RM6X6B-U9V0XUAD6-1902c9825828-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiamFhcCJ9.sstFIcmLQTvUWCBNOHqPuqYQsAJcBas-BJ_F1HVRfzQ"
        ),
        (
            "josh",
            "Joshua",
            "https://ca.slack-edge.com/T02RM6X6B-U0JNN4BFE-52b2c5f7e1f6-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiam9zaCJ9.SSK1tAzqDMmCei1Y498YDYhWIFljZzZtsCGmCdu5AC4"
        ),
        (
            "marcelo",
            "Marcelo Pires",
            "https://ca.slack-edge.com/T02RM6X6B-UD6TCA6P6-2b60e1b19771-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFyY2VsbyJ9.xpFoSta53fovRpyULXavYdv2qO5bLG0HpyEFxmYOMlY"
        ),
        (
            "vishal",
            "Vishal Narkhede",
            "https://ca.slack-edge.com/T02RM6X6B-UHGDQJ8A0-31658896398c-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidmlzaGFsIn0.LpDqH6U8V8Qg9sqGjz0bMQvOfWrWKAjPKqeODYM0Elk"
        ),
        (
            "thierry",
            "Thierry",
            "https://ca.slack-edge.com/T02RM6X6B-U02RM6X6D-g28a1278a98e-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidGhpZXJyeSJ9.iyGzbWInSA6B-0CE1Q9_lPOWjHvrWX3ypDhLYAL1UUs"
        ),
        (
            "merel",
            "Merel",
            "https://ca.slack-edge.com/T02RM6X6B-ULM9UDW58-4c56462d52a4-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWVyZWwifQ.JVArAc-pY81HkXtbGzuxHrzdf8A9BQ3ZlB5hqRv47D4"
        ),
        (
            "tommaso",
            "Tommaso Barbugli",
            "https://ca.slack-edge.com/T02RM6X6B-U02U7SJP4-0f65a5997877-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidG9tbWFzbyJ9.wuLqzU1D6RYKokmzkgyFvQ43lWF7dMVGt5NOLwHNqyc"
        ),
        (
            "luke",
            "Luke",
            "https://ca.slack-edge.com/T02RM6X6B-UHLLRBJBU-4d0ebdff049c-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZSJ9.zvTMRzjR5t4K5sK0VjczbPoOYhYxSdBeoa_P9jZuuiY"
        ),
        (
            "nick",
            "Nick Parson",
            "https://ca.slack-edge.com/T02RM6X6B-U10BF2R9R-2e7377522518-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibmljayJ9.vTiCq9nYrT3BJhILVSGMbC-mKzu-PHvBGPNWmLFH0mE"
        ),
        (
            "scott",
            "Scott",
            "https://ca.slack-edge.com/T02RM6X6B-U5KT650MQ-5a65b75846de-512",
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic2NvdHQifQ.gzFcAl2dONxXWZmR1e-iUXOK-RIa1Gi7IfcNeq4hY5M"
        )
    ].map {
        UserCredentials(id: $0.0, name: $0.1, avatarURL: URL(string: $0.2)!, token: $0.3, apiKey: apiKeyString)
    }
}
