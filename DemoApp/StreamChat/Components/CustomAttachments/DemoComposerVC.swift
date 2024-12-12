//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreLocation
import StreamChat
import StreamChatUI
import UIKit

class DemoComposerVC: ComposerVC {
    private lazy var currentUserLocationProvider = CurrentUserLocationProvider()

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        currentUserLocationProvider.stopMonitoringLocation()
    }

    func addStaticLocationToAttachments() {
        currentUserLocationProvider.getCurrentLocation { [weak self] result in
            switch result {
            case .success(let location):
                let staticLocationPayload = StaticLocationAttachmentPayload(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                self?.content.attachments.append(AnyAttachmentPayload(payload: staticLocationPayload))
            case .failure(let error):
                if error is LocationPermissionError {
                    self?.showLocationPermissionAlert()
                }
            }
        }
    }

    func sendInstantStaticLocation() {
        currentUserLocationProvider.getCurrentLocation { [weak self] result in
            switch result {
            case .success(let location):
                let staticLocationPayload = StaticLocationAttachmentPayload(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                self?.channelController?.sendStaticLocation(staticLocationPayload)
            case .failure(let error):
                if error is LocationPermissionError {
                    self?.showLocationPermissionAlert()
                }
            }
        }
    }

    var throttler = Throttler(interval: 5)
    var messageId: MessageId?

    func sendInstantLiveLocation() {
        currentUserLocationProvider.startMonitoringLocation()
        currentUserLocationProvider.didUpdateLocation = { [weak self] location in
            self?.throttler.execute {
                let liveLocation = LiveLocationAttachmentPayload(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    stoppedSharing: false
                )
                debugPrint("newLiveLocation: \(liveLocation)")
                self?.channelController?.updateLiveLocation(liveLocation, messageId: self?.messageId) {
                    self?.messageId = try? $0.get()
                }
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

enum LocationPermissionError: Error {
    case permissionDenied
    case permissionRestricted
}

class CurrentUserLocationProvider: NSObject {
    private let locationManager: CLLocationManager
    private var onCurrentLocationFetch: ((Result<CLLocation, Error>) -> Void)?

    var didUpdateLocation: ((CLLocation) -> Void)?
    var lastLocation: CLLocation?
    var onError: ((Error) -> Void)?

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }

    func startMonitoringLocation() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startMonitoringSignificantLocationChanges()
        requestPermission { [weak self] error in
            guard let error else { return }
            self?.onError?(error)
        }
    }

    func stopMonitoringLocation() {
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    func getCurrentLocation(completion: @escaping (Result<CLLocation, Error>) -> Void) {
        onCurrentLocationFetch = completion
        if let lastLocation = lastLocation {
            onCurrentLocationFetch?(.success(lastLocation))
            onCurrentLocationFetch = nil
        } else {
            requestPermission { [weak self] error in
                guard let error else { return }
                self?.onCurrentLocationFetch?(.failure(error))
                self?.onCurrentLocationFetch = nil
            }
        }
    }

    func requestPermission(completion: @escaping (Error?) -> Void) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            completion(nil)
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            completion(nil)
        case .denied:
            completion(LocationPermissionError.permissionDenied)
        case .restricted:
            completion(LocationPermissionError.permissionRestricted)
        @unknown default:
            break
        }
    }
}

extension CurrentUserLocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        didUpdateLocation?(location)
        lastLocation = location
        onCurrentLocationFetch?(.success(location))
        onCurrentLocationFetch = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        onError?(error)
    }
}
