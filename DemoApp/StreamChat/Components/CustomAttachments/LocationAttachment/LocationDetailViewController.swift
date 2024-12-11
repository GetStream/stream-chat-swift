//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChat
import UIKit

class LocationDetailViewController: UIViewController {
    let locationAttachment: ChatMessageStaticLocationAttachment

    init(locationAttachment: ChatMessageStaticLocationAttachment) {
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
            latitude: locationAttachment.latitude,
            longitude: locationAttachment.longitude
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
