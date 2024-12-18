//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreLocation
@_spi(Experimental)
import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    private var locationProvider = LocationProvider.shared

    override var attachmentsPickerActions: [UIAlertAction] {
        var actions = super.attachmentsPickerActions
        
        let alreadyHasLocation = content.attachments.map(\.type).contains(.staticLocation)
        if AppConfig.shared.demoAppConfig.isLocationAttachmentsEnabled && !alreadyHasLocation {
            let addLocationAction = UIAlertAction(
                title: "Add Current Location",
                style: .default,
                handler: { [weak self] _ in
                    self?.addStaticLocationToAttachments()
                }
            )
            actions.append(addLocationAction)

            let sendLocationAction = UIAlertAction(
                title: "Send Current Location",
                style: .default,
                handler: { [weak self] _ in
                    self?.sendInstantStaticLocation()
                }
            )
            actions.append(sendLocationAction)

            let sendLiveLocationAction = UIAlertAction(
                title: "Share Live Location",
                style: .default,
                handler: { [weak self] _ in
                    self?.sendInstantLiveLocation()
                }
            )
            actions.append(sendLiveLocationAction)
        }

        return actions
    }

    func addStaticLocationToAttachments() {
        getCurrentLocationInfo { [weak self] location in
            guard let location = location else { return }
            let staticLocationPayload = StaticLocationAttachmentPayload(
                latitude: location.latitude,
                longitude: location.longitude
            )
            self?.content.attachments.append(AnyAttachmentPayload(payload: staticLocationPayload))
        }
    }

    func sendInstantStaticLocation() {
        getCurrentLocationInfo { [weak self] location in
            guard let location = location else { return }
            self?.channelController?.sendStaticLocation(location)
        }
    }

    func sendInstantLiveLocation() {
        getCurrentLocationInfo { [weak self] location in
            guard let location = location else { return }
            self?.channelController?.startLiveLocationSharing(location)
        }
    }

    private func getCurrentLocationInfo(completion: @escaping (LocationAttachmentInfo?) -> Void) {
        locationProvider.getCurrentLocation { [weak self] result in
            switch result {
            case .success(let location):
                let location = LocationAttachmentInfo(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                completion(location)
            case .failure(let error):
                if error is LocationPermissionError {
                    self?.showLocationPermissionAlert()
                }
                completion(nil)
            }
        }
    }

    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Location Access Required",
            message: "Please enable location access in Settings to share your location.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}
