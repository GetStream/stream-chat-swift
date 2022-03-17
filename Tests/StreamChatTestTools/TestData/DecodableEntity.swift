//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

protocol DecodableEntity: Decodable {
    var extraData: [String: RawJSON] { get }
}

extension MessagePayload: DecodableEntity {}
extension MessageReactionPayload: DecodableEntity {}
extension UserPayload: DecodableEntity {}
extension ChannelDetailPayload: DecodableEntity {}
