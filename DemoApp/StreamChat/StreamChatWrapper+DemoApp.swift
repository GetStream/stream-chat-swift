//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

extension StreamChatWrapper {
    // Instantiates chat client
    func setUpChat() {
        guard client == nil else {
            log.error("Client was already instantiated")
            return
        }

        // Set the log level
        LogConfig.level = .warning
        LogConfig.formatters = [
            PrefixLogFormatter(prefixes: [.info: "ℹ️", .debug: "🛠", .warning: "⚠️", .error: "🚨"])
        ]

        // Create Client
        client = ChatClient(config: config)
        client?.registerAttachment(LocationAttachmentPayload.self)

        // L10N
        let localizationProvider = Appearance.default.localizationProvider
        Appearance.default.localizationProvider = { key, table in
            let localizedString = localizationProvider(key, table)

            return localizedString == key
                ? Bundle.main.localizedString(forKey: key, value: nil, table: table)
                : localizedString
        }
    }

    func configureUI() {
        // Customize UI configuration
        Components.default.messageListDateSeparatorEnabled = true
        Components.default.messageListDateOverlayEnabled = true
        Components.default.messageAutoTranslationEnabled = true
        Components.default.isVoiceRecordingEnabled = true
        Components.default.isJumpToUnreadEnabled = true
        Components.default.messageSwipeToReplyEnabled = true
        Components.default.channelListSearchStrategy = .messages

        // Customize UI components
        Components.default.attachmentViewCatalog = DemoAttachmentViewCatalog.self
        Components.default.messageListVC = DemoChatMessageListVC.self
        Components.default.quotedMessageView = DemoQuotedChatMessageView.self
        Components.default.messageComposerVC = DemoComposerVC.self
        Components.default.channelContentView = DemoChatChannelListItemView.self
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.channelVC = DemoChatChannelVC.self
        Components.default.messageContentView = DemoChatMessageContentView.self
        Components.default.messageActionsVC = DemoChatMessageActionsVC.self
        Components.default.reactionsSorting = { $0.type.position < $1.type.position }
        Components.default.messageLayoutOptionsResolver = DemoChatMessageLayoutOptionsResolver()
        Components.default.mixedAttachmentInjector.register(.location, with: LocationAttachmentViewInjector.self)
    }
}

import MapKit
import UIKit

public extension AttachmentType {
    static let location = Self(rawValue: "custom_location")
}

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
}

public struct LocationAttachmentPayload: AttachmentPayload {
    public static var type: AttachmentType = .location

    var coordinate: Coordinate
}

public typealias ChatMessageLocationAttachment = ChatMessageAttachment<LocationAttachmentPayload>

class MapSnapshotView: _View {
    static var snapshotsCache: NSCache<NSString, UIImage> = .init()

    var coordinate: Coordinate? {
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

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapOnWorkoutAttachment))
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

class LocationAttachmentViewInjector: AttachmentViewInjector {
    lazy var mapSnapshotView = MapSnapshotView()

    var locationAttachment: ChatMessageLocationAttachment? {
        attachments(payloadType: LocationAttachmentPayload.self).first
    }

    override func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(mapSnapshotView, at: 0)

        NSLayoutConstraint.activate([
            mapSnapshotView.widthAnchor.constraint(equalToConstant: 250),
            mapSnapshotView.heightAnchor.constraint(equalToConstant: 150)
        ])

        mapSnapshotView.didTapOnLocation = { [weak self] in
            self?.handleTapOnLocationAttachment()
        }
    }

    override func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        mapSnapshotView.coordinate = locationAttachment?.coordinate
    }

    func handleTapOnLocationAttachment() {
        guard let locationAttachmentDelegate = contentView.delegate as? LocationAttachmentViewDelegate else {
            return
        }

        guard let locationAttachment = self.locationAttachment else {
            return
        }

        locationAttachmentDelegate.didTapOnLocationAttachment(locationAttachment)
    }
}

class DemoAttachmentViewCatalog: AttachmentViewCatalog {
    override class func attachmentViewInjectorClassFor(message: ChatMessage, components: Components) -> AttachmentViewInjector.Type? {
        guard message.attachmentCounts.keys.contains(.location) else {
            return super.attachmentViewInjectorClassFor(message: message, components: components)
        }

        let hasOtherAttachmentTypes = message.attachmentCounts.keys.count > 1
        if hasOtherAttachmentTypes {
            return MixedAttachmentViewInjector.self
        }

        return LocationAttachmentViewInjector.self
    }
}

class DemoComposerVC: ComposerVC {
    /// For demo purposes the locations are hard-coded.
    var dummyLocations: [(latitude: Double, longitude: Double)] = [
        (38.708442, -9.136822), // Lisbon, Portugal
        (51.5074, -0.1278), // London, United Kingdom
        (52.5200, 13.4050), // Berlin, Germany
        (40.4168, -3.7038), // Madrid, Spain
        (50.4501, 30.5234), // Kyiv, Ukraine
        (41.9028, 12.4964), // Rome, Italy
        (48.8566, 2.3522), // Paris, France
        (44.4268, 26.1025), // Bucharest, Romania
        (48.2082, 16.3738), // Vienna, Austria
        (47.4979, 19.0402) // Budapest, Hungary
    ]

    override var attachmentsPickerActions: [UIAlertAction] {
        let sendLocationAction = UIAlertAction(
            title: "Location",
            style: .default,
            handler: { [weak self] _ in self?.sendLocation() }
        )

        let actions = super.attachmentsPickerActions
        return actions + [sendLocationAction]
    }

    func sendLocation() {
        guard let location = dummyLocations.randomElement() else { return }
        let locationAttachmentPayload = LocationAttachmentPayload(
            coordinate: .init(latitude: location.latitude, longitude: location.longitude)
        )

        content.attachments.append(AnyAttachmentPayload(payload: locationAttachmentPayload))

        // In case you would want to send the location directly, without composer preview:
//        channelController?.createNewMessage(text: "", attachments: [.init(
//            payload: locationAttachmentPayload
//        )])
    }
}

/// Location Attachment Composer Preview
extension LocationAttachmentPayload: AttachmentPreviewProvider {
    public static let preferredAxis: NSLayoutConstraint.Axis = .vertical

    public func previewView(components: Components) -> UIView {
        let preview = MapSnapshotView()
        preview.coordinate = coordinate
        return preview
    }
}

protocol LocationAttachmentViewDelegate: ChatMessageContentViewDelegate {
    func didTapOnLocationAttachment(
        _ attachment: ChatMessageLocationAttachment
    )
}

class DemoChatMessageListVC: ChatMessageListVC, LocationAttachmentViewDelegate {
    func didTapOnLocationAttachment(_ attachment: ChatMessageLocationAttachment) {
        let mapViewController = MapViewController(locationAttachment: attachment)
        navigationController?.pushViewController(mapViewController, animated: true)
    }
}

class MapViewController: UIViewController {
    let locationAttachment: ChatMessageLocationAttachment

    init(locationAttachment: ChatMessageLocationAttachment) {
        self.locationAttachment = locationAttachment
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let mapView: MKMapView = {
        let view = MKMapView()
        view.isZoomEnabled = true
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let locationCoordinate = CLLocationCoordinate2D(
            latitude: locationAttachment.coordinate.latitude,
            longitude: locationAttachment.coordinate.longitude
        )

        mapView.region = .init(
            center: locationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        let annotation = MKPointAnnotation()
        annotation.coordinate = locationCoordinate
        mapView.addAnnotation(annotation)

        view = mapView
    }
}

class DemoQuotedChatMessageView: QuotedChatMessageView {
    override func setAttachmentPreview(for message: ChatMessage) {
        let locationAttachments = message.attachments(payloadType: LocationAttachmentPayload.self)
        if let locationPayload = locationAttachments.first?.payload {
            attachmentPreviewView.contentMode = .scaleAspectFit
            attachmentPreviewView.image = UIImage(
                systemName: "mappin.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(font: .boldSystemFont(ofSize: 12))
            )
            attachmentPreviewView.tintColor = .systemRed
            textView.text = """
            Location:
            (\(locationPayload.coordinate.latitude),\(locationPayload.coordinate.longitude))
            """
            return
        }

        super.setAttachmentPreview(for: message)
    }
}
