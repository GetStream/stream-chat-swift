//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import StreamChatUI
import UIKit

public extension AttachmentType {
    static let workout = Self(rawValue: "workout")
}

public struct WorkoutAttachmentPayload: AttachmentPayload {
    public var imageURL: URL
    
    public static var type: AttachmentType = .workout

    public var WorkoutDistanceMeters: Int?
    public var WorkoutType: String?
    public var WorkoutDurationSeconds: Int?
    public var WorkoutEnergyCal: Int?

    private enum CodingKeys: String, CodingKey {
        case WorkoutDistanceMeters = "workout-distance-meters"
        case WorkoutType = "workout-type"
        case WorkoutDurationSeconds = "workout-duration-seconds"
        case WorkoutEnergyCal = "workout-energy-cal"
        case imageURL = "image_url"
    }
}

open class WorkoutAttachmentViewInjector: AttachmentViewInjector {
    public private(set) var stackView: UIStackView = .init()
    public private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    public private(set) var distanceLabel: UILabel = .init()
    public private(set) var durationLabel: UILabel = .init()
    public private(set) var energyLabel: UILabel = .init()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually

        distanceLabel.backgroundColor = .yellow
        stackView.addArrangedSubview(distanceLabel)

        durationLabel.backgroundColor = .green
        stackView.addArrangedSubview(durationLabel)

        energyLabel.backgroundColor = .red
        stackView.addArrangedSubview(energyLabel)

        contentView.bubbleContentContainer.insertSubview(stackView, at: 0)

//        let container = contentView.bubbleView ?? contentView.bubbleContentContainer
//        stackView.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
        stackView.widthAnchor.constraint(equalToConstant: 200.0).isActive = true

        super.contentViewDidLayout(options: options)
    }

    override open func contentViewDidUpdateContent() {
        guard let attachment = attachments(payloadType: WorkoutAttachmentPayload.self).first else {
            return
        }

        let request = ImageRequest(
            url: attachment.imageURL,
            processors: [ImageProcessors.Resize(size: imageView.bounds.size)],
            priority: .high
        )
        Nuke.loadImage(with: request, into: imageView)
        distanceLabel.text = "you walked \(attachment.WorkoutDistanceMeters ?? 0) meters!"
        distanceLabel.text = "you walked \(attachment.WorkoutDistanceMeters ?? 0) meters!"
        energyLabel.text = "you walked \(attachment.WorkoutDistanceMeters ?? 0) meters!"
    }
}

class MyAttachmentViewCatalog: AttachmentViewCatalog {
    override class func attachmentViewInjectorClassFor(message: ChatMessage, components: Components) -> AttachmentViewInjector
        .Type? {
        guard message.attachmentCounts.keys.contains(.workout) else {
            return super.attachmentViewInjectorClassFor(message: message, components: components)
        }
        return WorkoutAttachmentViewInjector.self
    }
}

final class DemoAppCoordinator {
    private var connectionController: ChatConnectionController?
    private let navigationController: UINavigationController
    private let connectionDelegate: BannerShowingConnectionDelegate
    
    init(navigationController: UINavigationController) {
        // Since log is first touched in `BannerShowingConnectionDelegate`,
        // we need to set log level here
        LogConfig.level = .warning
        
        self.navigationController = navigationController
        connectionDelegate = BannerShowingConnectionDelegate(
            showUnder: navigationController.navigationBar
        )
        injectActions()
    }
    
    func presentChat(userCredentials: UserCredentials) {
        // Create a token
        let token = try! Token(rawValue: userCredentials.token)
        
        // Create client
        let config = ChatClientConfig(apiKey: .init(userCredentials.apiKey))
        let client = ChatClient(config: config, tokenProvider: .static(token))
        
        // Config
        Components.default.channelListRouter = DemoChatChannelListRouter.self
        Components.default.attachmentViewCatalog = MyAttachmentViewCatalog.self

//        let controller2 = client.channelController(for: ChannelId.init(type: .messaging, id: "default-channel-0"))
//        let attachment = WorkoutAttachmentPayload.init(WorkoutDistanceMeters: 150)
//
//        // TODO: make text not mandatory (or perhaps create a createMessageWithAttachments only)
//        controller2.createNewMessage(text: "work-out-test", attachments: [.init(payload: attachment)]) { _ in
//            print("look ma I worked out a lot")
//        }

        // Channels with the current user
        let controller = client.channelListController(query: .init(filter: .containMembers(userIds: [userCredentials.id])))
        let chatList = ChatChannelListVC()
        chatList.controller = controller
        
        connectionController = client.connectionController()
        connectionController?.delegate = connectionDelegate
        
        navigationController.viewControllers = [chatList]
        navigationController.isNavigationBarHidden = false
        
        let window = navigationController.view.window!
        
        UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromRight, animations: {
            window.rootViewController = self.navigationController
        })
    }
    
    private func injectActions() {
        if let loginViewController = navigationController.topViewController as? LoginViewController {
            loginViewController.didRequestChatPresentation = { [weak self] in
                self?.presentChat(userCredentials: $0)
            }
        }
    }
}
