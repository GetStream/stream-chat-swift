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

class WorkoutAttachmentView: _View {
    var content: _ChatMessageAttachment<WorkoutAttachmentPayload>? {
        didSet { updateContentIfNeeded() }
    }
    
    let imageView = UIImageView()
    let distanceLabel = UILabel()
    let durationLabel = UILabel()
    let energyLabel = UILabel()
    
    override func setUpAppearance() {
        super.setUpAppearance()
        
        distanceLabel.numberOfLines = 0
        durationLabel.numberOfLines = 0
        energyLabel.numberOfLines = 0
    }
    
    override func setUpLayout() {
        super.setUpLayout()
        let titleFont = UIFont(name: "HelveticaNeue-Bold", size: 16.0)
        let valueFont = UIFont(name: "HelveticaNeue-Bold", size: 14.0)

        distanceLabel.font = valueFont
        durationLabel.font = valueFont
        energyLabel.font = valueFont

        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)

        let distanceTitleLabel = UILabel()
        distanceTitleLabel.text = "Distance"
        distanceTitleLabel.textColor = #colorLiteral(red: 1, green: 0, blue: 0.0002603151661, alpha: 1)
        distanceTitleLabel.font = titleFont

        let durationTitleLabel = UILabel()
        durationTitleLabel.text = "Duration"
        durationTitleLabel.textColor = #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1)
        durationTitleLabel.font = titleFont
        
        let energyTitleLabel = UILabel()
        energyTitleLabel.text = "Energy"
        energyTitleLabel.textColor = #colorLiteral(red: 0, green: 1, blue: 0.9998726249, alpha: 1)
        energyTitleLabel.font = titleFont

        let distanceCell = ContainerStackView(arrangedSubviews: [distanceTitleLabel, distanceLabel])
        distanceCell.translatesAutoresizingMaskIntoConstraints = false
        distanceCell.distribution = .natural
        distanceCell.axis = .vertical

        let durationCell = ContainerStackView(arrangedSubviews: [durationTitleLabel, durationLabel])
        durationCell.translatesAutoresizingMaskIntoConstraints = false
        durationCell.distribution = .natural
        durationCell.axis = .vertical

        let energyCell = ContainerStackView(arrangedSubviews: [energyTitleLabel, energyLabel])
        energyCell.translatesAutoresizingMaskIntoConstraints = false
        energyCell.distribution = .natural
        energyCell.axis = .vertical

        let container = ContainerStackView(arrangedSubviews: [distanceCell, durationCell, energyCell])
        container.translatesAutoresizingMaskIntoConstraints = false
        container.distribution = .equal
        addSubview(container)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    override func updateContent() {
        super.updateContent()
        
        if let attachment = content {
            Nuke.loadImage(with: attachment.imageURL, into: imageView)
            distanceLabel.text = "\(attachment.WorkoutDistanceMeters ?? 0)"
            durationLabel.text = "\(attachment.WorkoutDurationSeconds ?? 0) "
            energyLabel.text = "\(attachment.WorkoutEnergyCal ?? 0)"
        } else {
            imageView.image = nil
            distanceLabel.text = nil
            durationLabel.text = nil
            energyLabel.text = nil
        }
    }
}

open class WorkoutAttachmentViewInjector: AttachmentViewInjector {
    let workoutView = WorkoutAttachmentView()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleContentContainer.insertArrangedSubview(workoutView, at: 0, respectsLayoutMargins: true)
    }

    override open func contentViewDidUpdateContent() {
        workoutView.content = attachments(payloadType: WorkoutAttachmentPayload.self).first
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
