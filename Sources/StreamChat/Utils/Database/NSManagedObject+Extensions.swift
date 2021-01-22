//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData

extension NSManagedObject {
    @objc class var entityName: String {
        "\(self)"
    }
}
