//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    var onDisconnect: (() -> Void)?

    lazy var streamModalTransitioningDelegate = StreamModalTransitioningDelegate()

    func showCreateNewChannelFlow() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let chatViewController = storyboard.instantiateViewController(withIdentifier: "CreateChatViewController") as? CreateChatViewController {
            chatViewController.searchController = rootViewController.controller.client.userSearchController()
            rootNavigationController?.pushViewController(chatViewController, animated: true)
        }
    }

    override func showCurrentUserProfile() {
        rootViewController.presentUserOptionsAlert(
            onLogout: onLogout,
            onDisconnect: onDisconnect,
            client: rootViewController.controller.client
        )
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
    // swiftlint:disable cyclomatic_complexity
    override func didTapMoreButton(for cid: ChannelId) {
        let client = rootViewController.controller.client
        let channelController = client.channelController(for: cid)
        let canUpdateChannel = channelController.channel?.canUpdateChannel == true
        let canUpdateChannelMembers = channelController.channel?.canUpdateChannelMembers == true
        let canBanChannelMembers = channelController.channel?.canBanChannelMembers == true
        let canFreezeChannel = channelController.channel?.canFreezeChannel == true
        let canMuteChannel = channelController.channel?.canMuteChannel == true
        let canSetChannelCooldown = channelController.channel?.canSetChannelCooldown == true
        let canSendMessage = channelController.channel?.canSendMessage == true
        let isPremiumMemberFeatureEnabled = AppConfig.shared.demoAppConfig.isPremiumMemberFeatureEnabled

        let actions: [UIAlertAction?] = [
            .init(title: "Change nav bar translucency", handler: { [unowned self] _ in
                self.rootViewController.presentAlert(
                    title: "Change nav bar translucency",
                    message: "Change the nav bar translucency to verify that the keyboard handling is working in different app setups.",
                    actions: [
                        .init(title: "Is Translucent", handler: { _ in
                            self.rootViewController.navigationController?.navigationBar.isTranslucent = true
                        }),
                        .init(title: "Not Translucent", handler: { _ in
                            self.rootViewController.navigationController?.navigationBar.isTranslucent = false
                        })
                    ],
                    cancelHandler: nil
                )
            }),
            .init(title: "Change channel presentation style", handler: { [unowned self] _ in
                self.rootViewController.presentAlert(
                    title: "Change channel presentation style",
                    message: "Change how the channel navigation is presented.",
                    actions: [
                        .init(title: "Push (Default)", handler: { _ in
                            self.channelPresentingStyle = .push
                        }),
                        .init(title: "Modally", handler: { _ in
                            self.channelPresentingStyle = .modally
                        }),
                        .init(title: "Embedded in Tab Bar", handler: { _ in
                            self.channelPresentingStyle = .embeddedInTabBar
                        })
                    ],
                    cancelHandler: nil
                )
                self.channelPresentingStyle = .embeddedInTabBar
            }),
            .init(title: "Update channel name", isEnabled: canUpdateChannel, handler: { [unowned self] _ in
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
                            Task { @MainActor in
                                self.rootViewController.presentAlert(
                                    title: "Couldn't update name of channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
                }
            }),
            .init(title: "Update channel image", isEnabled: canUpdateChannel, handler: { [unowned self] _ in
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
                            Task { @MainActor in
                                self.rootViewController.presentAlert(
                                    title: "Couldn't update image url of channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
                }
            }),
            .init(title: "Show Channel Info", handler: { [unowned self] _ in
                let debugViewController = DebugObjectViewController(object: channelController.channel)
                self.rootViewController.present(debugViewController, animated: true)
            }),
            .init(title: "Show Channel Members", handler: { [unowned self] _ in
                guard let cid = channelController.channel?.cid else { return }
                let client = channelController.client
                self.rootViewController.present(MembersViewController(
                    membersController: client.memberListController(query: .init(cid: cid, pageSize: 105))
                ), animated: true)
            }),
            .init(title: "Show Channel Premium Members", isVisible: isPremiumMemberFeatureEnabled, handler: { [unowned self] _ in
                guard let cid = channelController.channel?.cid else { return }
                let client = channelController.client
                self.rootViewController.present(MembersViewController(
                    membersController: client.memberListController(
                        query: .init(cid: cid, filter: .equal("is_premium", to: true), pageSize: 105)
                    )
                ), animated: true)
            }),
            .init(title: "Show Channel Moderators", handler: { [unowned self] _ in
                guard let cid = channelController.channel?.cid else { return }
                let client = channelController.client
                self.rootViewController.present(MembersViewController(
                    membersController: client.memberListController(
                        query: .init(cid: cid, filter: .equal(.isModerator, to: true))
                    )
                ), animated: true)
            }),
            .init(title: "Show Banned Members", handler: { [unowned self] _ in
                guard let cid = channelController.channel?.cid else { return }
                let client = channelController.client
                self.rootViewController.present(MembersViewController(
                    membersController: client.memberListController(
                        query: .init(cid: cid, filter: .equal(.banned, to: true))
                    )
                ), animated: true)
            }),
            .init(title: "Show Blocked Users", handler: { [unowned self] _ in
                guard let cid = channelController.channel?.cid else { return }
                let client = channelController.client
                client.currentUserController().loadBlockedUsers { result in
                    guard let blockedUsers = try? result.get() else { return }
                    Task { @MainActor in
                        self.rootViewController.present(MembersViewController(
                            membersController: client.memberListController(
                                query: .init(
                                    cid: cid,
                                    filter: .in(.id, values: blockedUsers.map(\.userId))
                                )
                            )
                        ), animated: true)
                    }
                }
            }),
            .init(title: "Load More Members", handler: { [unowned self] _ in
                channelController.loadMoreChannelReads(limit: 100) { error in
                    guard let error else { return }
                    Task { @MainActor in
                        self.rootViewController.presentAlert(
                            title: "Couldn't load more members to channel \(cid)",
                            message: "\(error)"
                        )
                    }
                }
            }),
            .init(title: "Add member", isEnabled: canUpdateChannelMembers, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                    guard let id = id, !id.isEmpty else {
                        self.rootViewController.presentAlert(title: "User ID is not valid")
                        return
                    }
                    channelController.addMembers(
                        [MemberInfo(userId: id, extraData: nil)],
                        message: "Members added to the channel"
                    ) { error in
                        if let error = error {
                            Task { @MainActor in
                                self.rootViewController.presentAlert(
                                    title: "Couldn't add user \(id) to channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
                }
            }),
            .init(title: "Add member w/o history", isEnabled: canUpdateChannelMembers, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                    guard let id = id, !id.isEmpty else {
                        self.rootViewController.presentAlert(title: "User ID is not valid")
                        return
                    }
                    channelController.addMembers(
                        [MemberInfo(userId: id, extraData: nil)],
                        hideHistory: true,
                        message: "Members added to the channel"
                    ) { error in
                        if let error = error {
                            Task { @MainActor in
                                self.rootViewController.presentAlert(
                                    title: "Couldn't add user \(id) to channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
                }
            }),
            .init(title: "Remove a member", isEnabled: canUpdateChannelMembers, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.removeMembers(
                            userIds: [member.id],
                            message: "Members removed from the channel"
                        ) { [unowned self] error in
                            Task { @MainActor in
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
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Ban member", isEnabled: canBanChannelMembers, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.client
                            .memberController(userId: member.id, in: channelController.cid!)
                            .ban { error in
                                if let error = error {
                                    Task { @MainActor in
                                        self.rootViewController.presentAlert(
                                            title: "Couldn't ban user \(member.id) from channel \(cid)",
                                            message: "\(error)"
                                        )
                                    }
                                }
                            }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Shadow ban member", isEnabled: canBanChannelMembers, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.client
                            .memberController(userId: member.id, in: channelController.cid!)
                            .shadowBan { error in
                                if let error = error {
                                    Task { @MainActor in
                                        self.rootViewController.presentAlert(
                                            title: "Couldn't ban user \(member.id) from channel \(cid)",
                                            message: "\(error)"
                                        )
                                    }
                                }
                            }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Unban member", isEnabled: canBanChannelMembers, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.client
                            .memberController(userId: member.id, in: channelController.cid!)
                            .unban { error in
                                if let error = error {
                                    Task { @MainActor in
                                        self.rootViewController.presentAlert(
                                            title: "Couldn't unban user \(member.id) from channel \(cid)",
                                            message: "\(error)"
                                        )
                                    }
                                }
                            }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Add premium member", isVisible: isPremiumMemberFeatureEnabled, isEnabled: canUpdateChannelMembers, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                    guard let id = id, !id.isEmpty else {
                        self.rootViewController.presentAlert(title: "User ID is not valid")
                        return
                    }
                    channelController.addMembers(
                        [MemberInfo(userId: id, extraData: ["is_premium": true])],
                        message: "Premium member added to the channel"
                    ) { error in
                        if let error = error {
                            Task { @MainActor in
                                self.rootViewController.presentAlert(
                                    title: "Couldn't add user \(id) to channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
                }
            }),
            .init(title: "Set member as premium", isVisible: isPremiumMemberFeatureEnabled, isEnabled: canUpdateChannelMembers, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.client.memberController(userId: member.id, in: cid)
                            .partialUpdate(extraData: ["is_premium": true], unsetProperties: nil) { [unowned self] result in
                                Task { @MainActor in
                                    do {
                                        let data = try result.get()
                                        print("Member updated. Premium: ", data.isPremium)
                                        self.rootNavigationController?.popViewController(animated: true)
                                    } catch {
                                        self.rootViewController.presentAlert(
                                            title: "Couldn't set user \(member.id) as premium.",
                                            message: "\(error)"
                                        )
                                    }
                                }
                            }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Set current member as premium", isVisible: isPremiumMemberFeatureEnabled, handler: { [unowned self] _ in
                channelController.client.currentUserController()
                    .updateMemberData(["is_premium": true], in: cid) { [unowned self] result in
                        Task { @MainActor in
                            do {
                                let data = try result.get()
                                print("Member updated. Premium: ", data.isPremium)
                                self.rootNavigationController?.popViewController(animated: true)
                            } catch {
                                self.rootViewController.presentAlert(
                                    title: "Couldn't set current user as premium.",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
            }),
            .init(title: "Unset premium from member", isVisible: isPremiumMemberFeatureEnabled, isEnabled: canUpdateChannelMembers, handler: { [unowned self] _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.client.memberController(userId: member.id, in: cid)
                            .partialUpdate(extraData: nil, unsetProperties: ["is_premium"]) { [unowned self] result in
                                Task { @MainActor in
                                    do {
                                        let data = try result.get()
                                        print("Member updated. Premium: ", data.isPremium)
                                        self.rootNavigationController?.popViewController(animated: true)
                                    } catch {
                                        self.rootViewController.presentAlert(
                                            title: "Couldn't set user \(member.id) as premium.",
                                            message: "\(error)"
                                        )
                                    }
                                }
                            }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Freeze channel", isEnabled: canFreezeChannel, handler: { [unowned self] _ in
                channelController.freezeChannel { error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(title: "Couldn't freeze channel \(cid)", message: "\(error)")
                        }
                    }
                }
            }),
            .init(title: "Unfreeze channel", isEnabled: canFreezeChannel, handler: { [unowned self] _ in
                channelController.unfreezeChannel { error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(title: "Couldn't unfreeze channel \(cid)", message: "\(error)")
                        }
                    }
                }
            }),
            .init(title: "Mute channel", isEnabled: canMuteChannel, handler: { [unowned self] _ in
                channelController.muteChannel { error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(title: "Couldn't mute channel \(cid)", message: "\(error)")
                        }
                    }
                }
            }),
            .init(title: "Mute channel with expiration", isEnabled: canMuteChannel, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter expiration", textFieldPlaceholder: "Seconds") { expiration in
                    guard let expiration = Int(expiration ?? ""), expiration != 0 else {
                        self.rootViewController.presentAlert(title: "Expiration is not valid")
                        return
                    }
                    channelController.muteChannel(expiration: expiration * 1000) { error in
                        if let error = error {
                            Task { @MainActor in
                                self.rootViewController.presentAlert(title: "Couldn't mute channel \(cid)", message: "\(error)")
                            }
                        }
                    }
                }
            }),
            .init(title: "Cool channel", isEnabled: canMuteChannel, handler: { [unowned self] _ in
                channelController.partialChannelUpdate(extraData: ["is_cool": true]) { error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(title: "Couldn't make a channel \(cid) cool", message: "\(error)")
                        }
                    }
                }
            }),
            .init(title: "Uncool channel", isEnabled: canMuteChannel, handler: { [unowned self] _ in
                channelController.partialChannelUpdate(extraData: ["is_cool": false]) { error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(title: "Couldn't make a channel \(cid) uncool", message: "\(error)")
                        }
                    }
                }
            }),
            .init(title: "Unmute channel", isEnabled: canMuteChannel, handler: { [unowned self] _ in
                channelController.unmuteChannel { error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(title: "Couldn't unmute channel \(cid)", message: "\(error)")
                        }
                    }
                }
            }),
            .init(title: "Pin channel", isEnabled: true, handler: { [unowned self] _ in
                channelController.pin { error in
                    guard let error else { return }
                    Task { @MainActor in
                        self.rootViewController.presentAlert(title: "Couldn't pin channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Unpin channel", isEnabled: true, handler: { [unowned self] _ in
                channelController.unpin { error in
                    guard let error else { return }
                    Task { @MainActor in
                        self.rootViewController.presentAlert(title: "Couldn't unpin channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Archive channel", isEnabled: true, handler: { [unowned self] _ in
                channelController.archive { error in
                    guard let error else { return }
                    Task { @MainActor in
                        self.rootViewController.presentAlert(title: "Couldn't archive channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Unarchive channel", isEnabled: true, handler: { [unowned self] _ in
                channelController.unarchive { error in
                    guard let error else { return }
                    Task { @MainActor in
                        self.rootViewController.presentAlert(title: "Couldn't unarchive channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Enable slow mode", isEnabled: canSetChannelCooldown, handler: { [unowned self] _ in
                self.rootViewController
                    .presentAlert(title: "Enter cooldown", textFieldPlaceholder: "Cooldown duration, 0-120") { cooldown in
                        guard let cooldown = cooldown, !cooldown.isEmpty, let duration = Int(cooldown) else {
                            self.rootViewController.presentAlert(title: "Cooldown duration is not valid")
                            return
                        }
                        channelController.enableSlowMode(cooldownDuration: duration) { [unowned self] error in
                            if let error = error {
                                Task { @MainActor in
                                    self.rootViewController.presentAlert(
                                        title: "Couldn't enable slow mode on channel \(cid)",
                                        message: "\(error)"
                                    )
                                }
                            }
                        }
                    }
            }),
            .init(title: "Disable slow mode", isEnabled: canSetChannelCooldown, handler: { [unowned self] _ in
                channelController.disableSlowMode { error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(
                                title: "Couldn't disable slow mode on channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Hide channel", isEnabled: channelController.channel?.isHidden == false, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(
                    title: "Clear History?",
                    message: nil,
                    actions: [
                        .init(title: "Clear History", handler: { _ in
                            channelController.hideChannel(clearHistory: true) { error in
                                if let error = error {
                                    Task { @MainActor in
                                        self.rootViewController.presentAlert(
                                            title: "Couldn't hide channel \(cid)",
                                            message: "\(error)"
                                        )
                                    }
                                }
                            }
                        }),
                        .init(title: "Keep History", handler: { _ in
                            channelController.hideChannel(clearHistory: false) { error in
                                if let error = error {
                                    Task { @MainActor in
                                        self.rootViewController.presentAlert(
                                            title: "Couldn't hide channel \(cid)",
                                            message: "\(error)"
                                        )
                                    }
                                }
                            }
                        })
                    ],
                    cancelHandler: nil
                )
            }),
            .init(title: "Show channel", isEnabled: channelController.channel?.isHidden == true, handler: { [unowned self] _ in
                channelController.showChannel { error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(
                                title: "Couldn't unhide channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Truncate channel w/o message", isEnabled: canUpdateChannel, handler: { _ in
                channelController.truncateChannel { [unowned self] error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(
                                title: "Couldn't truncate channel \(cid)",
                                message: "\(error.localizedDescription)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Truncate channel with message", isEnabled: canUpdateChannel, handler: { _ in
                channelController.truncateChannel(systemMessage: "Channel truncated") { [unowned self] error in
                    if let error = error {
                        Task { @MainActor in
                            self.rootViewController.presentAlert(
                                title: "Couldn't truncate channel \(cid)",
                                message: "\(error.localizedDescription)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Send message with skip push", isEnabled: canSendMessage, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter the message text", textFieldPlaceholder: "Send message") { message in
                    guard let message = message, !message.isEmpty else {
                        self.rootViewController.presentAlert(title: "Message is not valid")
                        return
                    }
                    channelController.createNewMessage(text: message, skipPush: true)
                }
            }),
            .init(title: "Say Hi to a specific member", isEnabled: canSendMessage, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter the channel member id", textFieldPlaceholder: "Send message") { userId in
                    guard let userId, !userId.isEmpty,
                          channelController.channel?.lastActiveMembers.map(\.id).contains(userId) == true else {
                        self.rootViewController.presentAlert(title: "user id is not valid")
                        return
                    }
                    channelController.createNewMessage(text: "Hi", restrictedVisibility: [userId])
                }
            }),
            .init(title: "Send and update restricted message", isEnabled: canSendMessage, handler: { [unowned self] _ in
                Task { @MainActor in
                    do {
                        let chat = client.makeChat(for: cid)
                        let currentUserId = client.currentUserId!
                        let otherUserId = chat.state.channel!.lastActiveMembers.first(where: { $0.id != currentUserId })!.id
                        let message = try await chat.sendMessage(with: "This is a restricted message only visible to myself", restrictedVisibility: [currentUserId])
                        try await Task.sleep(nanoseconds: 5_000_000_000)
                        try await chat.updateMessage(message.id, text: "This is visible to me and \(otherUserId)", restrictedVisibility: [currentUserId, otherUserId])
                    } catch {
                        self.rootViewController.presentAlert(title: error.localizedDescription)
                    }
                }
            }),
            .init(title: "Send system message", isEnabled: canSendMessage, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter the message text", textFieldPlaceholder: "Send message") { message in
                    guard let message = message, !message.isEmpty else {
                        self.rootViewController.presentAlert(title: "Message is not valid")
                        return
                    }
                    channelController.createSystemMessage(text: message)
                }
            }),
            .init(title: "Send message without url enriching", isEnabled: canSendMessage, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter the message text", textFieldPlaceholder: "Send message") { message in
                    guard let message = message, !message.isEmpty else {
                        self.rootViewController.presentAlert(title: "Message is not valid")
                        return
                    }
                    channelController.createNewMessage(text: message, skipEnrichUrl: true)
                }
            }),
            .init(title: "Show channel with message id", handler: { [unowned self] _ in
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
                        Task { @MainActor in
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
                }
            }),
            .init(title: "Delete Downloaded Attachments", handler: { [unowned self] _ in
                do {
                    let connectedUser = try self.rootViewController.controller.client.makeConnectedUser()
                    Task {
                        do {
                            try await connectedUser.deleteAllLocalAttachmentDownloads()
                        } catch {
                            self.rootViewController.presentAlert(title: error.localizedDescription)
                        }
                    }
                } catch {
                    self.rootViewController.presentAlert(title: error.localizedDescription)
                }
            }),
            .init(title: "Reset User Image", handler: { [unowned self] _ in
                channelController.client.currentUserController()
                    .updateUserData(unsetProperties: ["image"]) { [unowned self] error in
                        if let error {
                            Task { @MainActor in
                                self.rootViewController.presentAlert(title: error.localizedDescription)
                            }
                        }
                    }
            }),
            .init(title: "Add a team role for the current user", isEnabled: true, handler: { [unowned self] _ in
                self.rootViewController.presentAlert(title: "Enter the team role", textFieldPlaceholder: "Enter role") { role in
                    if let role, !role.isEmpty {
                        let userRole = UserRole(rawValue: role)
                        client.currentUserController().updateUserData(teamsRole: ["ios": userRole]) { error in
                            if let error {
                                log.error("Couldn't add role to custom team for the current user: \(error)")
                            }
                        }
                    }
                }
            })
        ]

        rootViewController.presentAlert(
            title: "Select an action",
            actions: actions.compactMap { $0 }
        )
    }

    // swiftlint:enable function_body_length
    // swiftlint:enable cyclomatic_complexity

    override func didTapDeleteButton(for cid: ChannelId) {
        rootViewController.controller.client.channelController(for: cid).deleteChannel { error in
            if let error = error {
                Task { @MainActor in
                    self.rootViewController.presentAlert(title: "Channel \(cid) couldn't be deleted", message: "\(error)")
                }
            }
        }
    }
}

private extension UIAlertAction {
    /// Convenience initializer to create an alert action with a custom isEnabled flag.
    /// - Parameters:
    ///  - title: The title of the action.
    ///  - isEnabled: The flag saying if the action is enabled.
    ///  - style: The style of the action.
    ///  - handler: The block to execute when the user selects the action.
    convenience init(
        title: String?,
        isEnabled: Bool = true,
        style: Style = .default,
        handler: ((UIAlertAction) -> Void)?
    ) {
        self.init(
            title: title,
            style: style,
            handler: handler
        )
        self.isEnabled = isEnabled
    }

    /// Convenience initializer to create an alert action only if should be visible.
    /// - Parameters:
    ///  - title: The title of the action.
    ///  - isVisible: The flag saying if the action should be visible.
    ///  - isEnabled: The flag saying if the action is enabled.
    ///  - style: The style of the action.
    ///  - handler: The block to execute when the user selects the action.
    convenience init?(
        title: String?,
        isVisible: Bool = true,
        isEnabled: Bool = true,
        style: Style = .default,
        handler: ((UIAlertAction) -> Void)?
    ) {
        if !isVisible {
            return nil
        }
        self.init(title: title, isEnabled: isEnabled, style: style, handler: handler)
    }
}
