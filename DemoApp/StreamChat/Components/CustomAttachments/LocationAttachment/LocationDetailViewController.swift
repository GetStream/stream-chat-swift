//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import MapKit
import UIKit

class LocationDetailViewController: UIViewController {
    let locationAttachment: ChatMessageLocationAttachment

    init(locationAttachment: ChatMessageLocationAttachment) {
        self.locationAttachment = locationAttachment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let mapView: MKMapView = {
        let view = MKMapView()
        view.isZoomEnabled = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let locationCoordinate = CLLocationCoordinate2D(
            latitude: locationAttachment.coordinate.latitude,
            longitude: locationAttachment.coordinate.longitude
        )

        mapView.region = .init(
            center: locationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinate
        mapView.addAnnotation(annotation)

        view = mapView
    }
}
