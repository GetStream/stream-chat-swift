//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension NameAndImageExtraData {
    /// Returns a dummy data with unique `name` and `imageURL`
    static var dummy: Self {
        .init(name: .unique, imageURL: .unique())
    }
}
