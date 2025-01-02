//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChat
import StreamChatUI
import UIKit

class LocationDetailViewController: UIViewController, ThemeProvider {
    let messageController: ChatMessageController

    init(
        messageController: ChatMessageController
    ) {
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

        messageController.synchronize()
        messageController.delegate = self

        var locationCoordinate: CLLocationCoordinate2D?
        if let staticLocationAttachment = messageController.message?.staticLocationAttachments.first {
            locationCoordinate = CLLocationCoordinate2D(
                latitude: staticLocationAttachment.latitude,
                longitude: staticLocationAttachment.longitude
            )
        } else if let liveLocationAttachment = messageController.message?.liveLocationAttachments.first {
            locationCoordinate = CLLocationCoordinate2D(
                latitude: liveLocationAttachment.latitude,
                longitude: liveLocationAttachment.longitude
            )
        }
        if let locationCoordinate {
            mapView.region = .init(
                center: locationCoordinate,
                span: coordinateSpan
            )
            updateUserLocation(
                locationCoordinate
            )
        }

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
        } else if let author = messageController.message?.author {
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
        
        let liveLocationAttachment = messageController.message?.liveLocationAttachments.first
        let isSharingLiveLocation = liveLocationAttachment?.stoppedSharing == false
        if isSharingLiveLocation {
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

    private var size: CGSize = .init(width: 40, height: 40)

    private var pulseLayer: CALayer?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = .gray
        frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.cornerRadius = 20
        layer.masksToBounds = false
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
        addSubview(avatarView)
        avatarView.width(size.width)
        avatarView.height(size.height)
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
        pulseLayer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        layer.insertSublayer(pulseLayer, below: avatarView.layer)

        let animationScale = CABasicAnimation(keyPath: "transform.scale")
        animationScale.fromValue = 1.0
        animationScale.toValue = 1.5
        animationScale.duration = 2.0
        animationScale.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animationScale.autoreverses = false
        animationScale.repeatCount = .infinity

        let animationOpacity = CABasicAnimation(keyPath: "opacity")
        animationOpacity.fromValue = 1.0
        animationOpacity.toValue = 0
        animationOpacity.duration = 2.0
        animationOpacity.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animationOpacity.autoreverses = false
        animationOpacity.repeatCount = .infinity

        pulseLayer.add(animationScale, forKey: "pulseScale")
        pulseLayer.add(animationOpacity, forKey: "pulseOpacity")
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
