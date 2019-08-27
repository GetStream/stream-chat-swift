//
//  Tests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 26/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

func isTests() -> Bool {
    #if DEBUG
    return NSClassFromString("XCTest") != nil
    #else
    return false
    #endif
}
