//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

protocol DecodableEntity: Decodable {
    var extraData: [String: RawJSON] { get }
}

extension MessageResponse: DecodableEntity {}
extension ReactionResponse: DecodableEntity { var extraData: [String: RawJSON] { custom } }
extension UserResponse: DecodableEntity { var extraData: [String: RawJSON] { custom } }
extension OwnUserResponse: DecodableEntity { var extraData: [String: RawJSON] { custom } }
extension ChannelResponse: DecodableEntity {}
