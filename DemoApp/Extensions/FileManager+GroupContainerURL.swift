//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension FileManager {
    var groupContainerURL: URL! { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: UserDefaults.groupId) }
}
