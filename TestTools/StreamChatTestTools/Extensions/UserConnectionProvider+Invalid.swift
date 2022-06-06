//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension UserConnectionProvider {
    static func invalid(_ error: Error = TestError()) -> Self {
        .init { $0(.failure(error)) }
    }
}
