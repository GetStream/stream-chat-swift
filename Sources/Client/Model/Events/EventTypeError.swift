//
//  EventTypeError.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 06/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

enum EventTypeError: Swift.Error {
    case unknownType(String)
    case cidNotFound
}
