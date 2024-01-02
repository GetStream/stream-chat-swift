//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChatUI
import UIKit

class LocationAttachmentSnapshotView: _View {
    static var snapshotsCache: NSCache<NSString, UIImage> = .init()

    var coordinate: LocationCoordinate? {
        didSet {
            updateContent()
        }
    }

    var snapshotter: MKMapSnapshotter?

    var didTapOnLocation: (() -> Void)?

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

        addSubview(activityIndicatorView)
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            activityIndicatorView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }

    @objc func handleTapOnWorkoutAttachment() {
        didTapOnLocation?()
    }

    override func updateContent() {
        super.updateContent()

        imageView.image = nil

        guard let coordinate = self.coordinate else {
            return
        }

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

        if imageView.image == nil {
            activityIndicatorView.startAnimating()
        }

        let key = NSString(string: "\(coordinate.latitude),\(coordinate.longitude)")
        if let snapshotImage = Self.snapshotsCache.object(forKey: key) {
            imageView.image = snapshotImage
        } else {
            snapshotter?.cancel()
            snapshotter = MKMapSnapshotter(options: mapOptions)
            snapshotter?.start { snapshot, _ in
                guard let snapshot = snapshot else { return }

                let image = UIGraphicsImageRenderer(size: self.mapOptions.size).image { _ in
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

                DispatchQueue.main.async {
                    self.activityIndicatorView.stopAnimating()
                    self.imageView.image = image
                    Self.snapshotsCache.setObject(image, forKey: key)
                }
            }
        }
    }
}
