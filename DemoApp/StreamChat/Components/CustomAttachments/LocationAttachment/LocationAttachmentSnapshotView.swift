//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import MapKit
import StreamChat
import StreamChatUI
import UIKit

class LocationAttachmentSnapshotView: _View, ThemeProvider {
    struct Content {
        var coordinate: CLLocationCoordinate2D
        var isLive: Bool
        var isSharingLiveLocation: Bool
        var messageId: MessageId?
        var author: ChatUser?

        init(coordinate: CLLocationCoordinate2D, isLive: Bool, isSharingLiveLocation: Bool, messageId: MessageId?, author: ChatUser?) {
            self.coordinate = coordinate
            self.isLive = isLive
            self.isSharingLiveLocation = isSharingLiveLocation
            self.messageId = messageId
            self.author = author
        }

        var isFromCurrentUser: Bool {
            author?.id == StreamChatWrapper.shared.client?.currentUserId
        }
    }

    var content: Content? {
        didSet {
            updateContent()
        }
    }

    var didTapOnLocation: (() -> Void)?
    var didTapOnStopSharingLocation: (() -> Void)?

    let mapHeightRatio: CGFloat = 0.7
    let mapOptions: MKMapSnapshotter.Options = .init()

    let avatarSize: CGFloat = 30

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

    lazy var avatarView: ChatUserAvatarView = {
        let view = ChatUserAvatarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.shouldShowOnlineIndicator = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = avatarSize / 2
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        view.isHidden = true
        return view
    }()

    lazy var sharingStatusView: LocationSharingStatusView = {
        let view = LocationSharingStatusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    override func setUp() {
        super.setUp()

        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTapOnWorkoutAttachment)
        )
        imageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = appearance.colorPalette.background6
    }

    override func setUpLayout() {
        super.setUpLayout()

        stopButton.isHidden = true
        activityIndicatorView.hidesWhenStopped = true

        addSubview(activityIndicatorView)

        let container = VContainer(spacing: 0, alignment: .center) {
            imageView
            sharingStatusView
                .height(30)
            stopButton
                .width(120)
                .height(35)
        }.embed(in: self)

        addSubview(avatarView)

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: container.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: mapHeightRatio),
            avatarView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize)
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
 
        avatarView.isHidden = true

        if content.isSharingLiveLocation && content.isFromCurrentUser {
            stopButton.isHidden = false
            sharingStatusView.isHidden = true
            sharingStatusView.updateStatus(isSharing: true)
        } else if content.isLive {
            stopButton.isHidden = true
            sharingStatusView.isHidden = false
            sharingStatusView.updateStatus(isSharing: content.isSharingLiveLocation)
        } else {
            stopButton.isHidden = true
            sharingStatusView.isHidden = true
        }

        configureMapPosition()
        loadMapSnapshotImage()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if frame.size.width != mapOptions.size.width {
            loadMapSnapshotImage()
        }
    }

    private func configureMapPosition() {
        guard let content = self.content else {
            return
        }

        mapOptions.region = .init(
            center: content.coordinate,
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

        mapOptions.size = CGSize(width: frame.width, height: frame.width * mapHeightRatio)

        if let cachedSnapshot = getCachedSnapshot() {
            imageView.image = cachedSnapshot
            updateAnnotationView()
            return
        } else {
            imageView.image = nil
        }

        activityIndicatorView.startAnimating()
        snapshotter?.cancel()
        snapshotter = MKMapSnapshotter(options: mapOptions)
        snapshotter?.start { snapshot, _ in
            guard let snapshot = snapshot else { return }
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()

                if let content = self.content, !content.isLive {
                    let image = self.drawPinOnSnapshot(snapshot)
                    self.imageView.image = image
                    self.setCachedSnapshot(image: image)
                } else {
                    self.imageView.image = snapshot.image
                    self.setCachedSnapshot(image: snapshot.image)
                }
                
                self.updateAnnotationView()
            }
        }
    }

    private func drawPinOnSnapshot(_ snapshot: MKMapSnapshotter.Snapshot) -> UIImage {
        UIGraphicsImageRenderer(size: mapOptions.size).image { _ in
            snapshot.image.draw(at: .zero)
            
            guard let content = self.content else { return }

            let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            let pinImage = pinView.image
            
            var point = snapshot.point(for: content.coordinate)
            point.x -= pinView.bounds.width / 2
            point.y -= pinView.bounds.height / 2
            point.x += pinView.centerOffset.x
            point.y += pinView.centerOffset.y
            
            pinImage?.draw(at: point)
        }
    }

    private func updateAnnotationView() {
        guard let content = self.content else { return }
        
        if content.isLive, let user = content.author {
            avatarView.isHidden = false
            avatarView.content = user
        } else {
            avatarView.isHidden = true
        }
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
