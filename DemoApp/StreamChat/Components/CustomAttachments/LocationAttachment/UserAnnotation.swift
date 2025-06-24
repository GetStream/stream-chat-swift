//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import MapKit
import StreamChat

class UserAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var user: ChatUser

    init(coordinate: CLLocationCoordinate2D, user: ChatUser) {
        self.coordinate = coordinate
        self.user = user
        super.init()
    }
}
