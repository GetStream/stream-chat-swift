//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

protocol DecodableEntity: Decodable {
    var extraData: [String: RawJSON] { get }
}

extension MessagePayload: DecodableEntity {
    var extraData: [String: RawJSON] { custom }
}

extension MessageReactionPayload: DecodableEntity {}
extension UserPayload: DecodableEntity {}
extension ChannelDetailPayload: DecodableEntity {}
extension CurrentUserPayload: DecodableEntity {}
