//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TestUser: Codable, Equatable {
    public let name: String
    public let age: Int

    public init(name: String, age: Int = 10) {
        self.name = name
        self.age = age
    }
}
