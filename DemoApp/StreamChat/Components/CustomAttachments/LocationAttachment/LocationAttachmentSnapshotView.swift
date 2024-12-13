//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChatUI
import UIKit

struct LocationCoordinate {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
}

class LocationAttachmentSnapshotView: _View {
    static var snapshotsCache: NSCache<NSString, UIImage> = .init()
    var snapshotter: MKMapSnapshotter?

    struct Content {
        var latitude: CLLocationDegrees
        var longitude: CLLocationDegrees
        var isLive: Bool = false
    }

    var content: Content? {
        didSet {
            updateContent()
        }
    }

    var didTapOnLocation: (() -> Void)?
    var didTapOnStopSharingLocation: (() -> Void)?

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.clipsToBounds = true
        view.layer.cornerRadius = 16
        view.contentMode = .scaleAspectFill
        return view
    }()

    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.style = .medium
        return view
    }()

    lazy var stopButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "stop.circle"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        button.setTitle("Stop Sharing", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.setTitleColor(.red, for: .normal)
        button.tintColor = .red
        button.backgroundColor = .clear
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(handleStopButtonTap), for: .touchUpInside)
        return button
    }()

    let mapOptions: MKMapSnapshotter.Options = .init()

    override func setUp() {
        super.setUp()

        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapOnWorkoutAttachment)
        )
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setUpLayout() {
        super.setUpLayout()

        stopButton.isHidden = true
        activityIndicatorView.hidesWhenStopped = true

        let container = VContainer(alignment: .center) {
            imageView
            stopButton
                .width(120)
                .height(30)
        }.embed(in: self)

        container.addSubview(activityIndicatorView)

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    @objc func handleTapOnWorkoutAttachment() {
        didTapOnLocation?()
    }

    override func updateContent() {
        super.updateContent()

        if content?.isLive == false {
            imageView.image = nil
        }
        
        guard let content = self.content else {
            return
        }

        if content.isLive {
            stopButton.isHidden = false
        } else {
            stopButton.isHidden = true
        }

        let coordinate = LocationCoordinate(
            latitude: content.latitude,
            longitude: content.longitude
        )
        configureMapPosition(coordinate: coordinate)

        if let snapshotImage = Self.snapshotsCache.object(forKey: coordinate.cachingKey) {
            imageView.image = snapshotImage
        } else {
            activityIndicatorView.startAnimating()
            loadMapSnapshotImage(coordinate: coordinate)
        }
    }

    private func configureMapPosition(coordinate: LocationCoordinate) {
        mapOptions.region = .init(
            center: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        )
        mapOptions.size = CGSize(width: 250, height: 150)
    }

    private func loadMapSnapshotImage(coordinate: LocationCoordinate) {
        snapshotter?.cancel()
        snapshotter = MKMapSnapshotter(options: mapOptions)
        snapshotter?.start { snapshot, _ in
            guard let snapshot = snapshot else { return }
            let image = self.generatePinAnnotation(for: snapshot, with: coordinate)
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.imageView.image = image
                Self.snapshotsCache.setObject(image, forKey: coordinate.cachingKey)
            }
        }
    }

    private func generatePinAnnotation(
        for snapshot: MKMapSnapshotter.Snapshot,
        with coordinate: LocationCoordinate
    ) -> UIImage {
        let image = UIGraphicsImageRenderer(size: mapOptions.size).image { _ in
            snapshot.image.draw(at: .zero)

            let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            let pinImage = pinView.image

            var point = snapshot.point(for: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ))
            point.x -= pinView.bounds.width / 2
            point.y -= pinView.bounds.height / 2
            point.x += pinView.centerOffset.x
            point.y += pinView.centerOffset.y
            pinImage?.draw(at: point)
        }
        return image
    }

    @objc private func handleStopButtonTap() {
        didTapOnStopSharingLocation?()
    }
}

private extension LocationCoordinate {
    var cachingKey: NSString {
        NSString(string: "\(latitude),\(longitude)")
    }
}
