//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreLocation
import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    private lazy var locationManager = CLLocationManager()

    var sharingType: LocationSharingType = .addToAttachments

    enum LocationSharingType {
        case addToAttachments
        case instant
    }

    override var attachmentsPickerActions: [UIAlertAction] {
        var actions = super.attachmentsPickerActions
        
        let alreadyHasLocation = content.attachments.map(\.type).contains(.staticLocation)
        if AppConfig.shared.demoAppConfig.isLocationAttachmentsEnabled && !alreadyHasLocation {
            let addLocationAction = UIAlertAction(
                title: "Add Current Location",
                style: .default,
                handler: { [weak self] _ in
                    self?.sharingType = .addToAttachments
                    self?.requestLocationPermission()
                }
            )
            actions.append(addLocationAction)

            let sendLocationAction = UIAlertAction(
                title: "Send Current Location",
                style: .default,
                handler: { [weak self] _ in
                    self?.sharingType = .instant
                    self?.requestLocationPermission()
                }
            )
            actions.append(sendLocationAction)
        }

        return actions
    }

    override func setUp() {
        super.setUp()

        locationManager = CLLocationManager()
    }

    private func requestLocationPermission() {
        locationManager.delegate = self

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            showLocationPermissionAlert()
        @unknown default:
            break
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

// MARK: - CLLocationManagerDelegate

extension DemoComposerVC: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        let locationPayload = StaticLocationAttachmentPayload(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        switch sharingType {
        case .addToAttachments:
            content.attachments.append(AnyAttachmentPayload(payload: locationPayload))
        case .instant:
            channelController?.sendStaticLocation(locationPayload)
        }

        // We only send the location once so we can stop updating the location.
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
