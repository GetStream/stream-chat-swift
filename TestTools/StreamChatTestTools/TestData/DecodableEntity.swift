//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

protocol DecodableEntity: Decodable {
    var custom: [String: RawJSON]? { get }
}
