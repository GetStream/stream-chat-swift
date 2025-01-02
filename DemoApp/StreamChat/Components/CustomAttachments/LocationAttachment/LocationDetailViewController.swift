//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChat
import StreamChatUI
import UIKit

class LocationDetailViewController: UIViewController, ThemeProvider {
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
        mapView.showsUserLocation = false
        mapView.delegate = self

        messageController?.synchronize()
        messageController?.delegate = self

        mapView.region = .init(
            center: locationCoordinate,
            span: coordinateSpan
        )
        updateUserLocation(
            locationCoordinate
        )

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
            locationCoordinate
        )
    }

    func updateUserLocation(
        _ coordinate: CLLocationCoordinate2D
    ) {
        if let existingAnnotation = userAnnotation {
            UIView.animate(withDuration: 5) {
                existingAnnotation.coordinate = coordinate
            }
            UIView.animate(withDuration: 5, delay: 0.2, options: .curveEaseOut) {
                self.mapView.setCenter(coordinate, animated: true)
            }
        } else if let author = messageController?.message?.author {
            // Create new annotation
            let userAnnotation = UserAnnotation(
                coordinate: coordinate,
                user: author
            )
            mapView.addAnnotation(userAnnotation)
            self.userAnnotation = userAnnotation
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

        annotationView?.setUser(userAnnotation.user)
        if isLive {
            annotationView?.startPulsingAnimation()
        } else {
            annotationView?.stopPulsingAnimation()
        }
        return annotationView
    }
}

class UserAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var user: ChatUser

    init(coordinate: CLLocationCoordinate2D, user: ChatUser) {
        self.coordinate = coordinate
        self.user = user
        super.init()
    }
}

class UserAnnotationView: MKAnnotationView {
    private lazy var avatarView: ChatUserAvatarView = {
        let view = ChatUserAvatarView()
        view.shouldShowOnlineIndicator = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        return view
    }()

    private var pulseLayer: CALayer?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = .gray
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        layer.cornerRadius = 20
        layer.masksToBounds = false
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        addSubview(avatarView)
        avatarView.bounds = bounds
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setUser(_ user: ChatUser) {
        avatarView.content = user
    }

    func startPulsingAnimation() {
        guard pulseLayer == nil else {
            return
        }
        let pulseLayer = CALayer()
        pulseLayer.masksToBounds = false
        pulseLayer.frame = bounds
        pulseLayer.cornerRadius = bounds.width / 2
        pulseLayer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.4).cgColor
        layer.insertSublayer(pulseLayer, below: avatarView.layer)

        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.5
        animation.duration = 1.0
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.autoreverses = true
        animation.repeatCount = .infinity

        pulseLayer.add(animation, forKey: "pulse")
        self.pulseLayer = pulseLayer
    }

    func stopPulsingAnimation() {
        guard pulseLayer != nil else {
            return
        }
        pulseLayer?.removeFromSuperlayer()
        pulseLayer = nil
    }
}
