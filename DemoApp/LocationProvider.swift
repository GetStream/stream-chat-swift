//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreLocation
import Foundation

enum LocationPermissionError: Error {
    case permissionDenied
    case permissionRestricted
}

class LocationProvider: NSObject {
    private let locationManager: CLLocationManager
    private var onCurrentLocationFetch: ((Result<CLLocation, Error>) -> Void)?

    var didUpdateLocation: ((CLLocation) -> Void)?
    var lastLocation: CLLocation?
    var onError: ((Error) -> Void)?

    private init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
    }

    static let shared = LocationProvider()

    var isMonitoringLocation: Bool {
        locationManager.delegate != nil
    }

    func startMonitoringLocation() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.delegate = self
        requestPermission { [weak self] error in
            guard let error else { return }
            self?.onError?(error)
        }
    }

    func stopMonitoringLocation() {
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
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
        locationManager.delegate = self
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

extension LocationProvider: CLLocationManagerDelegate {
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
