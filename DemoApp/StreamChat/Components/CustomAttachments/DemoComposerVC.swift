//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    /// For demo purposes the locations are hard-coded.
    var dummyLocations: [(latitude: Double, longitude: Double)] = [
        (38.708442, -9.136822), // Lisbon, Portugal
        (37.983810, 23.727539), // Athens, Greece
        (53.149118, -6.079341), // Greystones, Ireland
        (41.11722, 20.80194), // Ohrid, Macedonia
        (51.5074, -0.1278), // London, United Kingdom
        (52.5200, 13.4050), // Berlin, Germany
        (40.4168, -3.7038), // Madrid, Spain
        (50.4501, 30.5234), // Kyiv, Ukraine
        (41.9028, 12.4964), // Rome, Italy
        (48.8566, 2.3522), // Paris, France
        (44.4268, 26.1025), // Bucharest, Romania
        (48.2082, 16.3738), // Vienna, Austria
        (47.4979, 19.0402) // Budapest, Hungary
    ]

    override var attachmentsPickerActions: [UIAlertAction] {
        var actions = super.attachmentsPickerActions
        
        let alreadyHasLocation = content.attachments.map(\.type).contains(.location)
        if AppConfig.shared.demoAppConfig.isLocationAttachmentsEnabled && !alreadyHasLocation {
            let sendLocationAction = UIAlertAction(
                title: "Location",
                style: .default,
                handler: { [weak self] _ in self?.sendLocation() }
            )
            actions.append(sendLocationAction)
        }

        return actions
    }

    func sendLocation() {
        guard let location = dummyLocations.randomElement() else { return }
        let locationAttachmentPayload = LocationAttachmentPayload(
            coordinate: .init(latitude: location.latitude, longitude: location.longitude)
        )

        content.attachments.append(AnyAttachmentPayload(payload: locationAttachmentPayload))

        // In case you would want to send the location directly, without composer preview:
//        channelController?.createNewMessage(text: "", attachments: [.init(
//            payload: locationAttachmentPayload
//        )])
    }
}
