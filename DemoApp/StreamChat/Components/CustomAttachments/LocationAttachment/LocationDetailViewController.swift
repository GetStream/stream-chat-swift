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

    private var userAnnotation: UserAnnotation?
    private let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

    let mapView: MKMapView = {
        let view = MKMapView()
        view.isZoomEnabled = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.register(
            UserAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: "UserAnnotation"
        )
        mapView.region = .init(
            center: locationCoordinate,
            span: coordinateSpan
        )
        mapView.showsUserLocation = false
        mapView.delegate = self

        messageController?.synchronize()
        messageController?.delegate = self

        view = mapView
    }
}

extension LocationDetailViewController: ChatMessageControllerDelegate {
    func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        guard let liveLocationAttachment = controller.message?.liveLocationAttachments.first else {
            return
        }

        let locationCoordinate = CLLocationCoordinate2D(
            latitude: liveLocationAttachment.latitude,
            longitude: liveLocationAttachment.longitude
        )

        updateUserLocation(
            locationCoordinate,
            userImage: UIImage(systemName: "location"),
            userName: messageController?.message?.author.name ?? ""
        )
    }

    func updateUserLocation(
        _ coordinate: CLLocationCoordinate2D,
        userImage: UIImage?,
        userName: String
    ) {
        if let existingAnnotation = userAnnotation {
            UIView.animate(withDuration: 5) {
                existingAnnotation.coordinate = coordinate
            }
            UIView.animate(withDuration: 5, delay: 0.2, options: .curveEaseOut) {
                self.mapView.setCenter(coordinate, animated: true)
            }
            if let annotationView = mapView.view(for: existingAnnotation) as? UserAnnotationView {
                annotationView.updateImage(userImage)
            }
        } else {
            // Create new annotation
            userAnnotation = UserAnnotation(
                coordinate: coordinate,
                image: userImage,
                title: userName
            )
            if let annotation = userAnnotation {
                mapView.addAnnotation(annotation)
            }
        }
    }
}

extension LocationDetailViewController: MKMapViewDelegate {
    func mapView(
        _ mapView: MKMapView,
        viewFor annotation: MKAnnotation
    ) -> MKAnnotationView? {
        guard let userAnnotation = annotation as? UserAnnotation else {
            return nil
        }

        let identifier = "UserAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: identifier,
            for: userAnnotation
        ) as? UserAnnotationView

        annotationView?.updateImage(userAnnotation.image)
        return annotationView
    }
}

// Custom annotation class to store user data
class UserAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var image: UIImage?
    var title: String?

    init(coordinate: CLLocationCoordinate2D, image: UIImage?, title: String?) {
        self.coordinate = coordinate
        self.image = image
        self.title = title
        super.init()
    }
}

// Custom annotation view with user avatar
class UserAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        layer.cornerRadius = 20
        layer.masksToBounds = true
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func updateImage(_ image: UIImage?) {
        self.image = image
    }
}
