//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreLocation
import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    private var locationProvider = LocationProvider.shared

    override var attachmentsPickerActions: [UIAlertAction] {
        var actions = super.attachmentsPickerActions

        let isDemoAppLocationsEnabled = AppConfig.shared.demoAppConfig.isLocationAttachmentsEnabled
        let isLocationEnabled = channelController?.channel?.config.sharedLocationsEnabled == true
        if isLocationEnabled && isDemoAppLocationsEnabled && content.isInsideThread == false {
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

    func sendInstantStaticLocation() {
        getCurrentLocationInfo { [weak self] location in
            guard let location = location else { return }
            self?.channelController?.sendStaticLocation(location)
        }
    }

    func sendInstantLiveLocation() {
        getCurrentLocationInfo { [weak self] location in
            guard let location = location else { return }
            let alertController = UIAlertController(
                title: "Share Live Location",
                message: "Select the duration for sharing your live location.",
                preferredStyle: .actionSheet
            )
            let durations: [(String, TimeInterval)] = [
                ("1 minute", 61),
                ("10 minutes", 600),
                ("1 hour", 3600)
            ]
            for (title, duration) in durations {
                let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                    let endDate = Date().addingTimeInterval(duration)
                    self?.channelController?.startLiveLocationSharing(location, endDate: endDate) { [weak self] result in
                        switch result {
                        case .success:
                            break
                        case .failure(let error):
                            self?.presentAlert(
                                title: "Could not start live location sharing",
                                message: error.localizedDescription
                            )
                        }
                    }
                }
                alertController.addAction(action)
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self?.present(alertController, animated: true)
        }
    }

    private func getCurrentLocationInfo(completion: @escaping (LocationInfo?) -> Void) {
        locationProvider.getCurrentLocation { [weak self] result in
            switch result {
            case .success(let location):
                let location = LocationInfo(
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

class DemoInputTextView: InputTextView {
    override func setUpAppearance() {
        backgroundColor = .clear
        textContainer.lineFragmentPadding = 8
        font = appearance.fonts.body
        textColor = appearance.colorPalette.text
        textAlignment = .natural
        adjustsFontForContentSizeCategory = true

        // Calling the layoutManager in debug builds loads a dynamic lib
        // Which causes a big performance penalty. So in our Demo App
        // we avoid the performance penalty, unless it is using the our internal scheme.
        if StreamRuntimeCheck.isStreamInternalConfiguration {
            layoutManager.allowsNonContiguousLayout = false
        }

        placeholderLabel.font = font
        placeholderLabel.textColor = appearance.colorPalette.subtitleText
        placeholderLabel.adjustsFontSizeToFitWidth = true
    }
}
