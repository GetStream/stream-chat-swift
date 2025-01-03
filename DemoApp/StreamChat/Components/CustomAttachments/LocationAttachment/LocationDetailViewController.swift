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

        title = "Location"
        navigationController?.navigationBar.backgroundColor = appearance.colorPalette.background

        mapView.register(
            UserAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: "UserAnnotation"
        )
        mapView.showsUserLocation = false
        mapView.delegate = self
        view.backgroundColor = appearance.colorPalette.background
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupBottomSheet()
    }

    func updateUserLocation(
        _ coordinate: CLLocationCoordinate2D
    ) {
        if let existingAnnotation = userAnnotation {
            // By setting the duration to 5, and since we update the location every 3s
            // this will make sure the annotation moves smoothly and has a constant animation.
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

    func setupBottomSheet() {
        if #available(iOS 16.0, *) {
            let bottomSheet = LocationBottomSheetViewController(
                messageController: messageController
            )
            let nav = UINavigationController(rootViewController: bottomSheet)
            nav.modalPresentationStyle = .pageSheet
            let customDetent = UISheetPresentationController.Detent.custom(resolver: { _ in
                60
            })
            nav.sheetPresentationController?.detents = [customDetent]
            nav.sheetPresentationController?.prefersGrabberVisible = false
            nav.sheetPresentationController?.preferredCornerRadius = 16
            nav.sheetPresentationController?.largestUndimmedDetentIdentifier = customDetent.identifier
            nav.isModalInPresentation = true
            present(nav, animated: true)
        }
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

class LocationBottomSheetViewController: UIViewController, ThemeProvider {
    let messageController: ChatMessageController

    init(
        messageController: ChatMessageController
    ) {
        self.messageController = messageController
        super.init(nibName: nil, bundle: nil)
    }

    lazy var sharingButton: UIButton = {
        let button = UIButton()
        button.setTitle("Stop Sharing", for: .normal)
        button.setTitleColor(appearance.colorPalette.alert, for: .normal)
        button.titleLabel?.font = appearance.fonts.body
        button.addTarget(self, action: #selector(stopSharing), for: .touchUpInside)
        return button
    }()

    lazy var locationUpdateLabel: UILabel = {
        let label = UILabel()
        label.text = "Location updated 5 minutes ago"
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.subtitleText
        return label
    }()

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = appearance.colorPalette.background6

        let container = VContainer(spacing: 2, alignment: .center) {
            sharingButton
            locationUpdateLabel
        }

        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    @objc func stopSharing() {
        messageController.stopLiveLocationSharing()
    }
}
