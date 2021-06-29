//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UserConnectionInfo<ExtraData: ExtraDataTypes> {
    let name: String?
    let imageURL: URL?
    let extraData: ExtraData.User?
}
