//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChat
import UIKit

class LocationDetailViewController: UIViewController {
    let locationCoordinate: CLLocationCoordinate2D
    let isLive: Bool
    let messageController: ChatMessageController?

    init(
        locationCoordinate: CLLocationCoordinate2D,
        isLive: Bool,
        messageController: ChatMessageController?
    ) {
        self.locationCoordinate = locationCoordinate
        self.isLive = isLive
        self.messageController = messageController
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
