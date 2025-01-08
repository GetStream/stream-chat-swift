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
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isZoomEnabled = true
        return view
    }()

    var isLiveLocationAttachment: Bool {
        messageController.message?.liveLocationAttachments.first != nil
    }

    private lazy var locationControlBanner: LocationControlBannerView = {
        let banner = LocationControlBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.onStopSharingTapped = { [weak self] in
            self?.messageController.stopLiveLocationSharing()
        }
        return banner
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        messageController.synchronize()
        messageController.delegate = self

        title = "Location"
        navigationController?.navigationBar.backgroundColor = appearance.colorPalette.background

        mapView.register(
            UserAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: UserAnnotationView.reuseIdentifier
        )
        mapView.showsUserLocation = false
        mapView.delegate = self
        view.backgroundColor = appearance.colorPalette.background
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if isLiveLocationAttachment {
            view.addSubview(locationControlBanner)
            NSLayoutConstraint.activate([
                locationControlBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                locationControlBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                locationControlBanner.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                locationControlBanner.heightAnchor.constraint(equalToConstant: 90)
            ])
            // Make sure the Apple's Map logo is visible
            mapView.layoutMargins.bottom = 60
        }

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

        updateBannerState()
    }

    func updateUserLocation(
        _ coordinate: CLLocationCoordinate2D
    ) {
        if let existingAnnotation = userAnnotation {
            if isLiveLocationAttachment {
                // Since we update the location every 3s, by updating the coordinate with 5s animation
                // this will make sure the annotation moves smoothly.
                // This results in a "Tracking" like behaviour. This also blocks the user from moving the map.
                // In a real app, we could have a toggle to enable/disable this behaviour.
                UIView.animate(withDuration: 5) {
                    existingAnnotation.coordinate = coordinate
                }
                UIView.animate(withDuration: 5, delay: 0.2, options: .curveEaseOut) {
                    self.mapView.setCenter(coordinate, animated: true)
                }
            } else {
                existingAnnotation.coordinate = coordinate
                mapView.setCenter(coordinate, animated: true)
            }
        } else if let author = messageController.message?.author, isLiveLocationAttachment {
            let userAnnotation = UserAnnotation(
                coordinate: coordinate,
                user: author
            )
            mapView.addAnnotation(userAnnotation)
            self.userAnnotation = userAnnotation
        } else {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }

    private func updateBannerState() {
        guard let liveLocationAttachment = messageController.message?.liveLocationAttachments.first else {
            return
        }

        let isSharingLiveLocation = liveLocationAttachment.stoppedSharing == false

        let dateFormatter = appearance.formatters.channelListMessageTimestamp
        let updatedAtText = dateFormatter.format(messageController.message?.updatedAt ?? Date())
        locationControlBanner.configure(
            isSharingEnabled: isSharingLiveLocation,
            statusText: isSharingLiveLocation
                ? "Location sharing is active"
                : "Location last updated at \(updatedAtText)"
        )
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

        let isLiveLocationSharingStopped = liveLocationAttachment.stoppedSharing == true
        if isLiveLocationSharingStopped, let userAnnotation = self.userAnnotation {
            let userAnnotationView = mapView.view(for: userAnnotation) as? UserAnnotationView
            userAnnotationView?.stopPulsingAnimation()
        }

        updateBannerState()
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

        let annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: UserAnnotationView.reuseIdentifier,
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

class LocationControlBannerView: UIView, ThemeProvider {
    var onStopSharingTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var sharingButton: UIButton = {
        let button = UIButton()
        button.setTitle("Stop Sharing", for: .normal)
        button.setTitleColor(appearance.colorPalette.alert, for: .normal)
        button.titleLabel?.font = appearance.fonts.body
        button.addTarget(self, action: #selector(stopSharingTapped), for: .touchUpInside)
        return button
    }()

    private lazy var locationUpdateLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.subtitleText
        return label
    }()
    
    private func setupView() {
        backgroundColor = appearance.colorPalette.background6
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let container = VContainer(spacing: 0, alignment: .center) {
            sharingButton
            locationUpdateLabel
        }

        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    @objc private func stopSharingTapped() {
        onStopSharingTapped?()
    }
    
    func configure(isSharingEnabled: Bool, statusText: String) {
        sharingButton.isEnabled = isSharingEnabled
        sharingButton.setTitle(
            isSharingEnabled ? "Stop Sharing" : "Live location ended",
            for: .normal
        )

        let buttonColor = appearance.colorPalette.alert
        sharingButton.setTitleColor(
            isSharingEnabled ? buttonColor : buttonColor.withAlphaComponent(0.6),
            for: .normal
        )
        
        locationUpdateLabel.text = statusText
    }
}
