//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChat
import StreamChatUI
import UIKit

class LocationAttachmentSnapshotView: _View, ThemeProvider {
    struct Content {
        var messageId: MessageId?
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

    let mapOptions: MKMapSnapshotter.Options = .init()
    let mapHeight: CGFloat = 150

    static var snapshotsCache: NSCache<NSString, UIImage> = .init()
    var snapshotter: MKMapSnapshotter?

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
        button.setTitle("Stop Sharing", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.setTitleColor(appearance.colorPalette.alert, for: .normal)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(handleStopButtonTap), for: .touchUpInside)
        return button
    }()

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

        addSubview(activityIndicatorView)

        let container = VContainer(alignment: .center) {
            imageView
                .height(mapHeight)
            stopButton
                .width(120)
                .height(35)
        }.embed(in: self)

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: container.widthAnchor)
        ])
    }

    @objc func handleTapOnWorkoutAttachment() {
        didTapOnLocation?()
    }

    override func updateContent() {
        super.updateContent()

        guard let content = self.content else {
            return
        }

        if content.isLive {
            stopButton.isHidden = false
        } else {
            stopButton.isHidden = true
        }

        configureMapPosition()
        loadMapSnapshotImage()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if frame.size.width != mapOptions.size.width {
            imageView.image = nil
            clearSnapshotCache()
            loadMapSnapshotImage()
        }
    }

    private func configureMapPosition() {
        guard let content = self.content else {
            return
        }

        mapOptions.region = .init(
            center: CLLocationCoordinate2D(
                latitude: content.latitude,
                longitude: content.longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        )
    }

    private func loadMapSnapshotImage() {
        guard frame.size != .zero else {
            return
        }

        mapOptions.size = CGSize(width: frame.width, height: mapHeight)

        if let cachedSnapshot = getCachedSnapshot() {
            imageView.image = cachedSnapshot
            return
        } else {
            imageView.image = nil
        }

        activityIndicatorView.startAnimating()
        snapshotter?.cancel()
        snapshotter = MKMapSnapshotter(options: mapOptions)
        snapshotter?.start { snapshot, _ in
            guard let snapshot = snapshot else { return }
            let image = self.generatePinAnnotation(for: snapshot)
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.imageView.image = image
                self.setCachedSnapshot(image: image)
            }
        }
    }

    private func generatePinAnnotation(
        for snapshot: MKMapSnapshotter.Snapshot
    ) -> UIImage {
        let image = UIGraphicsImageRenderer(size: mapOptions.size).image { _ in
            snapshot.image.draw(at: .zero)

            let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            let pinImage = pinView.image

            guard let content = self.content else {
                return
            }

            var point = snapshot.point(for: CLLocationCoordinate2D(
                latitude: content.latitude,
                longitude: content.longitude
            ))
            point.x -= pinView.bounds.width / 2
            point.y -= pinView.bounds.height / 2
            point.x += pinView.centerOffset.x
            point.y += pinView.centerOffset.y
            pinImage?.draw(at: point)
        }
        return image
    }

    @objc func handleStopButtonTap() {
        didTapOnStopSharingLocation?()
    }

    // MARK: Snapshot Caching Management

    func setCachedSnapshot(image: UIImage) {
        guard let cachingKey = cachingKey() else {
            return
        }

        Self.snapshotsCache.setObject(image, forKey: cachingKey)
    }

    func getCachedSnapshot() -> UIImage? {
        guard let cachingKey = cachingKey() else {
            return nil
        }

        return Self.snapshotsCache.object(forKey: cachingKey)
    }

    func clearSnapshotCache() {
        Self.snapshotsCache.removeAllObjects()
    }

    private func cachingKey() -> NSString? {
        guard let content = self.content else {
            return nil
        }
        guard let messageId = content.messageId else {
            return nil
        }
        return NSString(string: "\(messageId)")
    }
}
