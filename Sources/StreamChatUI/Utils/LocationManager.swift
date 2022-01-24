//
//  LocationManager.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 04/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

import UIKit
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {

    // MARK: Variables
    static let shared = LocationManager()
    var locationManager: CLLocationManager?
    var location: Dynamic<CLLocation> = Dynamic(CLLocation())

    private override init() {
        super.init()
    }

    func hasLocationPermissionDenied() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .restricted, .denied:
                return true
            default:
                return false
            }
        } else {
            print("Location services are not enabled")
            return true
        }
        /*if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                return true
            default:
                return false
            }
        } else {
            print("Location services are not enabled")
            return false
        }*/
    }

    func requestLocationAuthorization() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }

    func requestGPS() {
        self.locationManager?.requestLocation()
    }

    func isEmptyCurrentLoc() -> Bool {
        return location.value.coordinate.latitude == 0 && location.value.coordinate.longitude == 0
    }

    class func getDistanceInKm(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to) / 1000
    }

    class func showLocationPermissionAlert() {
        let alertController = UIAlertController(title: "Location Permission Required", message: "Please enable location permissions in settings.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Settings", style: .default, handler: {(cAlertAction) in
            //Redirect to Settings app
            UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        UIApplication.shared.getTopViewController()?.present(alertController, animated: true, completion: nil)
    }
}

extension LocationManager {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            return
        }
        self.location.value = lastLocation
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // check the authorization status changes here
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(#function)
        if (error as? CLError)?.code == .denied {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
        }
    }
}
