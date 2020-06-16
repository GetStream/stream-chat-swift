//
// TypingEvents.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// TODO: These are just placeholder events!

struct TypingStart<ExtraData: ExtraDataTypes>: Event {
    static var eventRawType: String { "typing.start" }
    let user: UserModel<ExtraData.User>
}

struct TypingStop<ExtraData: ExtraDataTypes>: Event {
    static var eventRawType: String { "typing.stop" }
    let user: UserModel<ExtraData.User>
}
