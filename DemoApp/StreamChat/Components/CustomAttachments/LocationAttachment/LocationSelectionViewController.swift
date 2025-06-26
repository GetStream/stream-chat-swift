//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreLocation
import MapKit
import StreamChat
import StreamChatUI
import UIKit

class LocationSelectionViewController: UIViewController, ThemeProvider {
    private let channelController: ChatChannelController
    private let locationProvider = LocationProvider.shared
    private var currentLocation: CLLocation?
    
    init(channelController: ChatChannelController) {
        self.channelController = channelController
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var mapView: MKMapView = {
        let view = MKMapView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isZoomEnabled = true
        view.showsCompass = false
        view.showsUserLocation = true
        return view
    }()
    
    private lazy var staticLocationButton: LocationOptionButton = {
        let button = LocationOptionButton()
        button.configure(
            icon: UIImage(systemName: "mappin.circle"),
            title: "Send Current Location",
            subtitle: "Share your current location once"
        )
        button.addTarget(self, action: #selector(sendStaticLocationTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private lazy var liveLocationButton: LocationOptionButton = {
        let button = LocationOptionButton()
        button.configure(
            icon: UIImage(systemName: "location.circle"),
            title: "Share Live Location",
            subtitle: "Share your location in real-time"
        )
        button.addTarget(self, action: #selector(shareLiveLocationTapped), for: .touchUpInside)
        button.isEnabled = false
        button.layer.borderColor = appearance.colorPalette.accentPrimary.cgColor
        return button
    }()
    
    private lazy var bottomContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = appearance.colorPalette.background
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupConstraints()
        getCurrentLocation()
        
        title = "Share Location"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if currentLocation == nil {
            getCurrentLocation()
        }
    }

    private func setupView() {
        view.backgroundColor = appearance.colorPalette.background
        
        view.addSubview(mapView)
        view.addSubview(bottomContainer)

        VContainer(spacing: 8) {
            liveLocationButton
            staticLocationButton
        }
        .padding(top: 20, leading: 16, bottom: 20, trailing: 16)
        .embed(in: bottomContainer)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor),
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomContainer.heightAnchor.constraint(equalToConstant: 220)
        ])
    }
    
    private func getCurrentLocation() {
        locationProvider.getCurrentLocation { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let location):
                    self?.handleLocationReceived(location)
                case .failure:
                    self?.showLocationPermissionAlert()
                }
            }
        }
    }
    
    private func handleLocationReceived(_ location: CLLocation) {
        currentLocation = location
        
        let coordinate = location.coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
        mapView.userTrackingMode = .follow

        staticLocationButton.isEnabled = true
        liveLocationButton.isEnabled = true
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Location Access Required",
            message: "Please enable location access in Settings to share your location.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sendStaticLocationTapped() {
        guard let location = currentLocation else { return }
        
        let locationInfo = LocationInfo(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        channelController.sendStaticLocation(locationInfo)
        dismiss(animated: true)
    }
    
    @objc private func shareLiveLocationTapped() {
        guard let location = currentLocation else { return }
        
        let alertController = UIAlertController(
            title: "Share Live Location",
            message: "Select the duration for sharing your live location.",
            preferredStyle: .actionSheet
        )
        
        let durations: [(String, TimeInterval)] = [
            ("1 minute", 61),
            ("10 minutes", 600),
            ("1 hour", 3600)
        ]
        
        for (title, duration) in durations {
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self, let location = self.currentLocation else { return }
                
                let locationInfo = LocationInfo(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                let endDate = Date().addingTimeInterval(duration)
                
                self.channelController.startLiveLocationSharing(locationInfo, endDate: endDate) { [weak self] result in
                    switch result {
                    case .success:
                        self?.dismiss(animated: true)
                    case .failure(let error):
                        self?.presentAlert(
                            title: "Could not start live location sharing",
                            message: error.localizedDescription
                        )
                    }
                }
            }
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

class LocationOptionButton: UIButton, ThemeProvider {
    private let iconImageView = UIImageView()
    private let textLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    private func setupButton() {
        backgroundColor = appearance.colorPalette.background
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = appearance.colorPalette.border.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = appearance.colorPalette.accentPrimary

        textLabel.font = appearance.fonts.bodyBold
        textLabel.textColor = appearance.colorPalette.text
        textLabel.numberOfLines = 1

        descriptionLabel.font = appearance.fonts.footnote
        descriptionLabel.textColor = appearance.colorPalette.subtitleText
        descriptionLabel.numberOfLines = 1

        let container = HContainer(spacing: 16, alignment: .center) {
            iconImageView
                .width(24)
                .height(24)
            VContainer(spacing: 2, alignment: .leading) {
                textLabel
                descriptionLabel
            }
        }
        .padding(top: 12, leading: 16, bottom: 12, trailing: 16)
        .height(68)
        .embed(in: self)
        
        container.isUserInteractionEnabled = false
    }

    func configure(icon: UIImage?, title: String, subtitle: String) {
        iconImageView.image = icon
        textLabel.text = title
        descriptionLabel.text = subtitle
    }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.5
        }
    }

    override var isHighlighted: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        updateBackgroundColor()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        updateBackgroundColor()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        updateBackgroundColor()
    }

    private func updateBackgroundColor() {
        UIView.animate(withDuration: 0.1) {
            if self.isHighlighted {
                self.backgroundColor = self.appearance.colorPalette.background6
            } else {
                self.backgroundColor = self.appearance.colorPalette.background
            }
        }
    }
}
