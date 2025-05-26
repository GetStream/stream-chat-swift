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

    var isLiveLocation: Bool {
        messageController.message?.sharedLocation?.isLive == true
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

        if isLiveLocation {
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
        if let location = messageController.message?.sharedLocation {
            locationCoordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
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
            if isLiveLocation {
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
        } else if let author = messageController.message?.author, isLiveLocation {
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
        guard let location = messageController.message?.sharedLocation, location.isLive else {
            return
        }

        let isFromCurrentUser = messageController.message?.isSentByCurrentUser == true
        let dateFormatter = appearance.formatters.channelListMessageTimestamp
        let updatedAtText = dateFormatter.format(messageController.message?.updatedAt ?? Date())
        if location.isLiveSharingActive {
            locationControlBanner.configure(
                state: isFromCurrentUser
                    ? .currentUserSharing
                    : .anotherUserSharing(lastUpdatedAtText: updatedAtText)
            )
        } else {
            locationControlBanner.configure(state: .ended(lastUpdatedAtText: updatedAtText))
        }
    }
}

extension LocationDetailViewController: ChatMessageControllerDelegate {
    func messageController(
        _ controller: ChatMessageController,
        didChangeMessage change: EntityChange<ChatMessage>
    ) {
        guard let location = messageController.message?.sharedLocation, location.isLive else {
            return
        }

        let locationCoordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )

        updateUserLocation(
            locationCoordinate
        )

        let isLiveLocationSharingStopped = location.isLiveSharingActive == false
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

        let location = messageController.message?.sharedLocation
        if location?.isLiveSharingActive == true {
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

    enum State {
        case currentUserSharing
        case anotherUserSharing(lastUpdatedAtText: String)
        case ended(lastUpdatedAtText: String)
    }

    func configure(state: State) {
        switch state {
        case .currentUserSharing:
            sharingButton.isEnabled = true
            sharingButton.setTitle("Stop Sharing", for: .normal)
            sharingButton.setTitleColor(appearance.colorPalette.alert, for: .normal)
            locationUpdateLabel.text = "Location sharing is active"
        case .anotherUserSharing(let lastUpdatedAtText):
            sharingButton.isEnabled = false
            sharingButton.setTitle("Live Location", for: .normal)
            sharingButton.setTitleColor(appearance.colorPalette.alert, for: .normal)
            locationUpdateLabel.text = "Location last updated at \(lastUpdatedAtText)"
        case .ended(let lastUpdatedAtText):
            sharingButton.isEnabled = false
            sharingButton.setTitle("Live location ended", for: .normal)
            sharingButton.setTitleColor(appearance.colorPalette.alert.withAlphaComponent(0.6), for: .normal)
            locationUpdateLabel.text = "Location last updated at \(lastUpdatedAtText)"
        }
    }
}
