//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class DemoChatChannelListRouter: ChatChannelListRouter {
    enum ChannelPresentingStyle {
        case push
        case modally
        case embeddedInTabBar
    }

    var channelPresentingStyle: ChannelPresentingStyle = .push
    var onLogout: (() -> Void)?

    lazy var streamModalTransitioningDelegate = StreamModalTransitioningDelegate()

    func showCreateNewChannelFlow() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let chatViewController = storyboard.instantiateViewController(withIdentifier: "CreateChatViewController") as? CreateChatViewController {
            chatViewController.searchController = rootViewController.controller.client.userSearchController()
            rootNavigationController?.pushViewController(chatViewController, animated: true)
        }
    }

    override func showCurrentUserProfile() {
        rootViewController.presentAlert(title: nil, actions: [
            .init(title: "Show Profile", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                let client = self.rootViewController.controller.client
                let viewController = UserProfileViewController(currentUserController: client.currentUserController())
                self.rootNavigationController?.pushViewController(viewController, animated: true)
            }),
            .init(title: "Logout", style: .destructive, handler: { [weak self] _ in
                self?.onLogout?()
            })
        ])
    }

    override func showChannel(for cid: ChannelId) {
        switch channelPresentingStyle {
        case .push:
            super.showChannel(for: cid)

        case .modally:
            let vc = components.channelVC.init()
            vc.channelController = rootViewController.controller.client.channelController(for: cid)
            let navVc = UINavigationController(rootViewController: vc)
            navVc.transitioningDelegate = streamModalTransitioningDelegate
            navVc.modalPresentationStyle = .custom
            rootNavigationController?.present(navVc, animated: true, completion: nil)

        case .embeddedInTabBar:
            let vc = components.channelVC.init()
            vc.channelController = rootViewController.controller.client.channelController(for: cid)
            vc.tabBarItem = .init(title: "Chat", image: nil, tag: 0)

            let dummyViewController = UIViewController()
            dummyViewController.tabBarItem = .init(title: "Dummy", image: nil, tag: 1)

            let tabBarController = UITabBarController()
            tabBarController.view.backgroundColor = .systemBackground
            tabBarController.viewControllers = [vc, dummyViewController]
            // Make the tab bar not translucent to make sure the
            // keyboard handling works in all conditions.
            tabBarController.tabBar.isTranslucent = false

            rootNavigationController?.show(tabBarController, sender: self)
        }
    }

    // swiftlint:disable function_body_length
    override func didTapMoreButton(for cid: ChannelId) {
        let channelController = rootViewController.controller.client.channelController(for: cid)
        rootViewController.presentAlert(title: "Select an action", actions: [
            .init(title: "Change nav bar translucency", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(
                    title: "Change nav bar translucency",
                    message: "Change the nav bar translucency to verify that the keyboard handling is working in different app setups.",
                    actions: [
                        .init(title: "Is Translucent", style: .default, handler: { _ in
                            self.rootViewController.navigationController?.navigationBar.isTranslucent = true
                        }),
                        .init(title: "Not Translucent", style: .default, handler: { _ in
                            self.rootViewController.navigationController?.navigationBar.isTranslucent = false
                        })
                    ],
                    cancelHandler: nil
                )
            }),
            .init(title: "Change channel presentation style", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(
                    title: "Change channel presentation style",
                    message: "Change how the channel navigation is presented.",
                    actions: [
                        .init(title: "Push (Default)", style: .default, handler: { _ in
                            self.channelPresentingStyle = .push
                        }),
                        .init(title: "Modally", style: .default, handler: { _ in
                            self.channelPresentingStyle = .modally
                        }),
                        .init(title: "Embedded in Tab Bar", style: .default, handler: { _ in
                            self.channelPresentingStyle = .embeddedInTabBar
                        })
                    ],
                    cancelHandler: nil
                )
                self.channelPresentingStyle = .embeddedInTabBar
            }),
            .init(title: "Update channel name", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter channel name", textFieldPlaceholder: "Channel name") { name in
                    guard let name = name, !name.isEmpty else {
                        self.rootViewController.presentAlert(title: "Name is not valid")
                        return
                    }
                    channelController.updateChannel(
                        name: name,
                        imageURL: channelController.channel?.imageURL,
                        team: channelController.channel?.team
                    ) { [unowned self] error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't update name of channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Update channel image", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(
                    title: "Enter channel image url",
                    textFieldPlaceholder: "Channel image url, must be valid"
                ) { imageURL in
                    guard let imageURL = imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) else {
                        self.rootViewController.presentAlert(title: "URL is not valid")
                        return
                    }
                    channelController.updateChannel(
                        name: channelController.channel?.name,
                        imageURL: url,
                        team: channelController.channel?.team,
                        extraData: channelController.channel?.extraData ?? [:]
                    ) { [unowned self] error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't update image url of channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Add member", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                    guard let id = id, !id.isEmpty else {
                        self.rootViewController.presentAlert(title: "User ID is not valid")
                        return
                    }
                    channelController.addMembers(userIds: [id]) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't add user \(id) to channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Add member w/o history", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                    guard let id = id, !id.isEmpty else {
                        self.rootViewController.presentAlert(title: "User ID is not valid")
                        return
                    }
                    channelController.addMembers(userIds: [id], hideHistory: true) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't add user \(id) to channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Remove a member", style: .default, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.removeMembers(userIds: [member.id]) { [unowned self] error in
                            if let error = error {
                                self.rootViewController.presentAlert(
                                    title: "Couldn't remove user \(member.id) from channel \(cid)",
                                    message: "\(error)"
                                )
                            } else {
                                self.rootNavigationController?.popViewController(animated: true)
                            }
                        }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Ban member", style: .default, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.client
                            .memberController(userId: member.id, in: channelController.cid!)
                            .ban { error in
                                if let error = error {
                                    self.rootViewController.presentAlert(
                                        title: "Couldn't ban user \(member.id) from channel \(cid)",
                                        message: "\(error)"
                                    )
                                }
                            }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Unban member", style: .default, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.client
                            .memberController(userId: member.id, in: channelController.cid!)
                            .unban { error in
                                if let error = error {
                                    self.rootViewController.presentAlert(
                                        title: "Couldn't unban user \(member.id) from channel \(cid)",
                                        message: "\(error)"
                                    )
                                }
                            }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Freeze channel", style: .default, handler: { [unowned self] _ in
                channelController.freezeChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't freeze channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Unfreeze channel", style: .default, handler: { [unowned self] _ in
                channelController.unfreezeChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't unfreeze channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Mute channel", style: .default, handler: { [unowned self] _ in
                channelController.muteChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't mute channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Unmute channel", style: .default, handler: { [unowned self] _ in
                channelController.unmuteChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't unmute channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Freeze channel", style: .default, handler: { [unowned self] _ in
                channelController.freezeChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't freeze channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Enable slow mode", style: .default, handler: { [unowned self] _ in
                self.rootViewController
                    .presentAlert(title: "Enter cooldown", textFieldPlaceholder: "Cooldown duration, 0-120") { cooldown in
                        guard let cooldown = cooldown, !cooldown.isEmpty, let duration = Int(cooldown) else {
                            self.rootViewController.presentAlert(title: "Cooldown duration is not valid")
                            return
                        }
                        channelController.enableSlowMode(cooldownDuration: duration) { [unowned self] error in
                            if let error = error {
                                self.rootViewController.presentAlert(
                                    title: "Couldn't enable slow mode on channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
            }),
            .init(title: "Disable slow mode", style: .default, handler: { [unowned self] _ in
                channelController.disableSlowMode { error in
                    if let error = error {
                        self.rootViewController.presentAlert(
                            title: "Couldn't disable slow mode on channel \(cid)",
                            message: "\(error)"
                        )
                    }
                }
            }),
            (
                channelController.channel?.isHidden == false ?
                    .init(title: "Hide channel", style: .default, handler: { [unowned self] _ in
                        self.rootViewController.presentAlert(
                            title: "Clear History?",
                            message: nil,
                            actions: [
                                .init(title: "Clear History", style: .default, handler: { _ in
                                    channelController.hideChannel(clearHistory: true) { error in
                                        if let error = error {
                                            self.rootViewController.presentAlert(
                                                title: "Couldn't hide channel \(cid)",
                                                message: "\(error)"
                                            )
                                        }
                                    }
                                }),
                                .init(title: "Keep History", style: .default, handler: { _ in
                                    channelController.hideChannel(clearHistory: false) { error in
                                        if let error = error {
                                            self.rootViewController.presentAlert(
                                                title: "Couldn't hide channel \(cid)",
                                                message: "\(error)"
                                            )
                                        }
                                    }
                                })
                            ],
                            cancelHandler: nil
                        )
                    }) :
                    .init(title: "Show channel", style: .default, handler: { [unowned self] _ in
                        channelController.showChannel { error in
                            if let error = error {
                                self.rootViewController.presentAlert(
                                    title: "Couldn't unhide channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    })
            ),
            .init(title: "Show Channel Info", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(
                    title: "Channel Info",
                    message: channelController.channel.debugDescription
                )
            }),
            .init(title: "Truncate channel w/o message", style: .default, handler: { _ in
                channelController.truncateChannel { [unowned self] error in
                    if let error = error {
                        self.rootViewController.presentAlert(
                            title: "Couldn't truncate channel \(cid)",
                            message: "\(error.localizedDescription)"
                        )
                    }
                }
            }),
            .init(title: "Truncate channel with message", style: .default, handler: { _ in
                channelController.truncateChannel(systemMessage: "Channel truncated") { [unowned self] error in
                    if let error = error {
                        self.rootViewController.presentAlert(
                            title: "Couldn't truncate channel \(cid)",
                            message: "\(error.localizedDescription)"
                        )
                    }
                }
            }),
            .init(title: "Send message with skip push", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter the message text", textFieldPlaceholder: "Send message") { message in
                    guard let message = message, !message.isEmpty else {
                        self.rootViewController.presentAlert(title: "Message is not valid")
                        return
                    }
                    channelController.createNewMessage(text: message, skipPush: true)
                }
            }),
            .init(title: "Send message without url enriching", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter the message text", textFieldPlaceholder: "Send message") { message in
                    guard let message = message, !message.isEmpty else {
                        self.rootViewController.presentAlert(title: "Message is not valid")
                        return
                    }
                    channelController.createNewMessage(text: message, skipEnrichUrl: true)
                }
            }),
            .init(title: "Show channel with message id", style: .default, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(
                    title: "Enter message id",
                    textFieldPlaceholder: "Message ID"
                ) { id in
                    guard let id = id, !id.isEmpty else {
                        self.rootViewController.presentAlert(title: "Message ID is not valid")
                        return
                    }

                    let messageController = channelController.client.messageController(cid: cid, messageId: id)
                    messageController.synchronize { [weak self] error in
                        let message = messageController.message

                        var errorMessage: String? = error?.localizedDescription
                        if message?.cid != cid {
                            errorMessage = "Message ID does not belong to this channel."
                        }

                        if let errorMessage = errorMessage {
                            self?.rootViewController.presentAlert(title: errorMessage)
                            return
                        }

                        self?.showChannel(for: cid, at: message?.id)
                    }
                }
            })
        ])
    }

    // swiftlint:enable function_body_length

    override func didTapDeleteButton(for cid: ChannelId) {
        rootViewController.controller.client.channelController(for: cid).deleteChannel { error in
            if let error = error {
                self.rootViewController.presentAlert(title: "Channel \(cid) couldn't be deleted", message: "\(error)")
            }
        }
    }
}
