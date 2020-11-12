//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public protocol NameAndImageProviding {
    var displayName: String { get }
    var imageURL: URL? { get }
}

extension NameAndImageExtraData: NameAndImageProviding {
    public var displayName: String { name ?? "Missing name" }
}
