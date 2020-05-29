//
//  TestErrors.swift
//  StreamChatClient
//
//  Created by Vojta on 27/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Uniquely indetifiable error that can be used in tests.
struct TestError: Error, Equatable {
    let id = UUID()
}
