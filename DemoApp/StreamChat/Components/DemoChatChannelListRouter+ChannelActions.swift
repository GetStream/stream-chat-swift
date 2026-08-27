//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import UIKit

/// The values shared by all the channel actions of the demo app.
private struct ChannelActionsContext {
    let cid: ChannelId
    let client: ChatClient
    let channelController: ChatChannelController

    var channel: ChatChannel? { channelController.channel }
    var canUpdateChannel: Bool { channel?.canUpdateChannel == true }
    var canUpdateChannelMembers: Bool { channel?.canUpdateChannelMembers == true }
    var canBanChannelMembers: Bool { channel?.canBanChannelMembers == true }
    var canFreezeChannel: Bool { channel?.canFreezeChannel == true }
    var canMuteChannel: Bool { channel?.canMuteChannel == true }
    var canSetChannelCooldown: Bool { channel?.canSetChannelCooldown == true }
    var canSendMessage: Bool { channel?.canSendMessage == true }
    var isPremiumMemberFeatureEnabled: Bool { AppConfig.shared.demoAppConfig.isPremiumMemberFeatureEnabled }
}

extension DemoChatChannelListRouter {
    func presentChannelActions(for cid: ChannelId) {
        let client = rootViewController.controller.client
        let context = ChannelActionsContext(
            cid: cid,
            client: client,
            channelController: client.channelController(for: cid)
        )

        let group = DemoActionGroup(
            title: "Channel Actions",
            sections: [
                DemoActionSection("Channel", items: [
                    .menu("Channel Info", icon: "info.circle", sections: channelInfoSections(context)),
                    .menu("Channel Settings", icon: "gearshape", sections: channelSettingsSections(context)),
                    .menu("Channel State", icon: "archivebox", sections: channelStateSections(context))
                ]),
                DemoActionSection("People", items: [
                    .menu("Members", icon: "person.2", sections: membersSections(context)),
                    .menu("Moderation", icon: "shield", sections: moderationSections(context))
                ]),
                DemoActionSection("Messaging", items: [
                    .menu("Messages", icon: "bubble.left.and.bubble.right", sections: messagesSections(context)),
                    .menu("Reads & Notifications", icon: "bell.badge", sections: readsAndNotificationsSections(context))
                ]),
                DemoActionSection("Demo App", items: [
                    .menu("Presentation", icon: "rectangle.on.rectangle", sections: presentationSections(context)),
                    .menu("Current User & Local Data", icon: "person.crop.circle", sections: currentUserSections(context))
                ])
            ]
        )

        DemoActionsVC.present(group, from: rootViewController)
    }

    // MARK: - Channel Info

    private func channelInfoSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        [
            DemoActionSection(items: [
                .item("Show Channel Info") { [unowned self] in
                    let debugViewController = DebugObjectViewController(object: context.channel)
                    self.rootViewController.present(debugViewController, animated: true)
                },
                .item("Show Channel Threads") { [unowned self] in
                    guard let cid = context.channel?.cid else { return }
                    let threadListQuery = ThreadListQuery(watch: true, filter: .equal(.cid, to: cid.rawValue))
                    let threadListVC = ChatThreadListVC(
                        threadListController: context.client.threadListController(query: threadListQuery),
                        eventsController: context.client.eventsController()
                    )
                    threadListVC.title = "Channel Threads"
                    let navVC = UINavigationController(rootViewController: threadListVC)
                    self.rootViewController.present(navVC, animated: true)
                }
            ])
        ]
    }

    // MARK: - Channel Settings

    private func channelSettingsSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        let channelController = context.channelController
        let cid = context.cid

        return [
            DemoActionSection("Appearance", items: [
                .item("Update channel name", isEnabled: context.canUpdateChannel) { [unowned self] in
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
                },
                .item("Update channel image", isEnabled: context.canUpdateChannel) { [unowned self] in
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
                }
            ]),
            DemoActionSection("Custom Data", items: [
                .item("Cool channel", isEnabled: context.canMuteChannel) { [unowned self] in
                    channelController.partialChannelUpdate(extraData: ["is_cool": true]) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(title: "Couldn't make a channel \(cid) cool", message: "\(error)")
                        }
                    }
                },
                .item("Uncool channel", isEnabled: context.canMuteChannel) { [unowned self] in
                    channelController.partialChannelUpdate(extraData: ["is_cool": false]) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(title: "Couldn't make a channel \(cid) uncool", message: "\(error)")
                        }
                    }
                },
                .item("Toggle Premium Tag", isEnabled: context.canUpdateChannel) { [unowned self] in
                    let hasPremium = channelController.channel?.filterTags.contains("premium") ?? false
                    channelController.partialChannelUpdate(filterTags: hasPremium ? ["non-premium"] : ["premium"]) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't update the premium state of the channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            ]),
            DemoActionSection("Slow Mode", items: [
                .item("Enable slow mode", isEnabled: context.canSetChannelCooldown) { [unowned self] in
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
                },
                .item("Disable slow mode", isEnabled: context.canSetChannelCooldown) { [unowned self] in
                    channelController.disableSlowMode { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't disable slow mode on channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            ])
        ]
    }

    // MARK: - Channel State

    private func channelStateSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        let channelController = context.channelController
        let cid = context.cid

        return [
            DemoActionSection("Mute", items: [
                .item("Mute channel", isEnabled: context.canMuteChannel) { [unowned self] in
                    channelController.muteChannel { error in
                        if let error = error {
                            self.rootViewController.presentAlert(title: "Couldn't mute channel \(cid)", message: "\(error)")
                        }
                    }
                },
                .item("Mute channel with expiration", isEnabled: context.canMuteChannel) { [unowned self] in
                    self.rootViewController.presentAlert(title: "Enter expiration", textFieldPlaceholder: "Seconds") { expiration in
                        guard let expiration = Int(expiration ?? ""), expiration != 0 else {
                            self.rootViewController.presentAlert(title: "Expiration is not valid")
                            return
                        }
                        channelController.muteChannel(expiration: expiration * 1000) { error in
                            if let error = error {
                                self.rootViewController.presentAlert(title: "Couldn't mute channel \(cid)", message: "\(error)")
                            }
                        }
                    }
                },
                .item("Unmute channel", isEnabled: context.canMuteChannel) { [unowned self] in
                    channelController.unmuteChannel { error in
                        if let error = error {
                            self.rootViewController.presentAlert(title: "Couldn't unmute channel \(cid)", message: "\(error)")
                        }
                    }
                }
            ]),
            DemoActionSection("Pin & Archive", items: [
                .item("Pin channel") { [unowned self] in
                    channelController.pin { error in
                        guard let error else { return }
                        self.rootViewController.presentAlert(title: "Couldn't pin channel \(cid)", message: "\(error)")
                    }
                },
                .item("Unpin channel") { [unowned self] in
                    channelController.unpin { error in
                        guard let error else { return }
                        self.rootViewController.presentAlert(title: "Couldn't unpin channel \(cid)", message: "\(error)")
                    }
                },
                .item("Archive channel") { [unowned self] in
                    channelController.archive { error in
                        guard let error else { return }
                        self.rootViewController.presentAlert(title: "Couldn't archive channel \(cid)", message: "\(error)")
                    }
                },
                .item("Unarchive channel") { [unowned self] in
                    channelController.unarchive { error in
                        guard let error else { return }
                        self.rootViewController.presentAlert(title: "Couldn't unarchive channel \(cid)", message: "\(error)")
                    }
                }
            ]),
            DemoActionSection("Visibility", items: [
                .item("Hide channel", isEnabled: context.channel?.isHidden == false) { [unowned self] in
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
                },
                .item("Show channel", isEnabled: context.channel?.isHidden == true) { [unowned self] in
                    channelController.showChannel { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't unhide channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            ])
        ]
    }

    // MARK: - Members

    private func membersSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        let channelController = context.channelController
        let cid = context.cid

        return [
            DemoActionSection("Browse", items: [
                .item("Show Channel Members") { [unowned self] in
                    guard let cid = context.channel?.cid else { return }
                    self.rootViewController.present(MembersViewController(
                        membersController: context.client.memberListController(query: .init(cid: cid, pageSize: 105))
                    ), animated: true)
                },
                .item("Show Channel Moderators") { [unowned self] in
                    guard let cid = context.channel?.cid else { return }
                    self.rootViewController.present(MembersViewController(
                        membersController: context.client.memberListController(
                            query: .init(cid: cid, filter: .equal(.isModerator, to: true))
                        )
                    ), animated: true)
                },
                .item("Load More Members") { [unowned self] in
                    channelController.loadMoreChannelReads(limit: 100) { error in
                        guard let error else { return }
                        self.rootViewController.presentAlert(
                            title: "Couldn't load more members to channel \(cid)",
                            message: "\(error)"
                        )
                    }
                }
            ]),
            DemoActionSection("Manage", items: [
                .item("Add member", isEnabled: context.canUpdateChannelMembers) { [unowned self] in
                    self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                        guard let id = id, !id.isEmpty else {
                            self.rootViewController.presentAlert(title: "User ID is not valid")
                            return
                        }
                        self.rootViewController.presentAlert(
                            title: "How many days to show?",
                            message: "Enter the number of days of history to show, 0 for full history",
                            textFieldPlaceholder: "Days"
                        ) { daysString in
                            let hideHistoryBefore: Date? = {
                                guard let daysString, let days = Int(daysString) else { return nil }
                                return Calendar.current.date(byAdding: .day, value: -days, to: Date())
                            }()
                            channelController.addMembers(
                                [MemberInfo(userId: id, extraData: nil)],
                                hideHistoryBefore: hideHistoryBefore,
                                message: "Members added to the channel"
                            ) { error in
                                guard let error else { return }
                                self.rootViewController.presentAlert(
                                    title: "Couldn't add user \(id) to channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
                },
                .item("Add member w/o history", isEnabled: context.canUpdateChannelMembers) { [unowned self] in
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
                                self.rootViewController.presentAlert(
                                    title: "Couldn't add user \(id) to channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
                },
                .item("Add member with warning message", isEnabled: context.canUpdateChannelMembers) { [unowned self] in
                    self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                        guard let id = id, !id.isEmpty else {
                            self.rootViewController.presentAlert(title: "User ID is not valid")
                            return
                        }
                        channelController.addMembers(
                            [MemberInfo(userId: id, extraData: nil)],
                            systemMessage: .warning(text: "\(id) was added to the channel")
                        ) { error in
                            guard let error else { return }
                            self.rootViewController.presentAlert(
                                title: "Couldn't add user \(id) to channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                },
                .item("Remove a member", isEnabled: context.canUpdateChannelMembers) { [unowned self] in
                    self.presentMemberSelection(context) { member in
                        channelController.removeMembers(
                            userIds: [member.id],
                            message: "Members removed from the channel"
                        ) { [unowned self] error in
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
                },
                .item("Remove member with warning message", isEnabled: context.canUpdateChannelMembers) { [unowned self] in
                    self.presentMemberSelection(context) { member in
                        channelController.removeMembers(
                            userIds: [member.id],
                            systemMessage: .warning(text: "\(member.id) was removed from the channel")
                        ) { [unowned self] error in
                            guard let error else { return }
                            self.rootViewController.presentAlert(
                                title: "Couldn't remove user \(member.id) from channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            ]),
            DemoActionSection(items: [
                .menu(
                    "Premium Members",
                    icon: "star",
                    isVisible: context.isPremiumMemberFeatureEnabled,
                    items: premiumMemberActions(context)
                )
            ])
        ]
    }

    private func premiumMemberActions(_ context: ChannelActionsContext) -> [DemoAction?] {
        let cid = context.cid

        return [
            .item("Show Channel Premium Members") { [unowned self] in
                guard let cid = context.channel?.cid else { return }
                self.rootViewController.present(MembersViewController(
                    membersController: context.client.memberListController(
                        query: .init(cid: cid, filter: .equal("is_premium", to: true), pageSize: 105)
                    )
                ), animated: true)
            },
            .item("Add premium member", isEnabled: context.canUpdateChannelMembers) { [unowned self] in
                self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                    guard let id = id, !id.isEmpty else {
                        self.rootViewController.presentAlert(title: "User ID is not valid")
                        return
                    }
                    context.channelController.addMembers(
                        [MemberInfo(userId: id, extraData: ["is_premium": true])],
                        message: "Premium member added to the channel"
                    ) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't add user \(id) to channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            },
            .item("Set member as premium", isEnabled: context.canUpdateChannelMembers) { [unowned self] in
                self.presentMemberSelection(context) { member in
                    context.client.memberController(userId: member.id, in: cid)
                        .partialUpdate(extraData: ["is_premium": true], unsetProperties: nil) { [unowned self] result in
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
            },
            .item("Set current member as premium") { [unowned self] in
                context.client.currentUserController()
                    .updateMemberData(["is_premium": true], in: cid) { [unowned self] result in
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
            },
            .item("Unset premium from member", isEnabled: context.canUpdateChannelMembers) { [unowned self] in
                self.presentMemberSelection(context) { member in
                    context.client.memberController(userId: member.id, in: cid)
                        .partialUpdate(extraData: nil, unsetProperties: ["is_premium"]) { [unowned self] result in
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
        ]
    }

    // MARK: - Moderation

    private func moderationSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        let channelController = context.channelController
        let cid = context.cid

        return [
            DemoActionSection(items: [
                .menu("Bans", icon: "nosign", items: banActions(context)),
                .menu("Member Mutes", icon: "speaker.slash", items: memberMuteActions(context))
            ]),
            DemoActionSection("Blocked Users", items: blockActions(context)),
            DemoActionSection("Channel", items: [
                .item("Freeze channel", isEnabled: context.canFreezeChannel) { [unowned self] in
                    channelController.freezeChannel { error in
                        if let error = error {
                            self.rootViewController.presentAlert(title: "Couldn't freeze channel \(cid)", message: "\(error)")
                        }
                    }
                },
                .item("Unfreeze channel", isEnabled: context.canFreezeChannel) { [unowned self] in
                    channelController.unfreezeChannel { error in
                        if let error = error {
                            self.rootViewController.presentAlert(title: "Couldn't unfreeze channel \(cid)", message: "\(error)")
                        }
                    }
                }
            ]),
            DemoActionSection("Truncate", items: [
                .item("Truncate channel w/o message", isEnabled: context.canUpdateChannel, isDestructive: true) { [unowned self] in
                    channelController.truncateChannel { [unowned self] error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't truncate channel \(cid)",
                                message: "\(error.localizedDescription)"
                            )
                        }
                    }
                },
                .item("Truncate channel with message", isEnabled: context.canUpdateChannel, isDestructive: true) { [unowned self] in
                    channelController.truncateChannel(systemMessage: "Channel truncated") { [unowned self] error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't truncate channel \(cid)",
                                message: "\(error.localizedDescription)"
                            )
                        }
                    }
                }
            ])
        ]
    }

    private func banActions(_ context: ChannelActionsContext) -> [DemoAction?] {
        let cid = context.cid

        return [
            .item("Ban member", isEnabled: context.canBanChannelMembers) { [unowned self] in
                self.presentMemberSelection(context) { member in
                    context.client.memberController(userId: member.id, in: cid).ban { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't ban user \(member.id) from channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            },
            .item("Shadow ban member", isEnabled: context.canBanChannelMembers) { [unowned self] in
                self.presentMemberSelection(context) { member in
                    context.client.memberController(userId: member.id, in: cid).shadowBan { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't ban user \(member.id) from channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            },
            .item("Unban member", isEnabled: context.canBanChannelMembers) { [unowned self] in
                self.presentMemberSelection(context) { member in
                    context.client.memberController(userId: member.id, in: cid).unban { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't unban user \(member.id) from channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            },
            .item("Show Banned Members") { [unowned self] in
                guard let cid = context.channel?.cid else { return }
                self.rootViewController.present(MembersViewController(
                    membersController: context.client.memberListController(
                        query: .init(cid: cid, filter: .equal(.banned, to: true))
                    )
                ), animated: true)
            }
        ]
    }

    private func blockActions(_ context: ChannelActionsContext) -> [DemoAction?] {
        [
            .item("Show Blocked Users") { [unowned self] in
                guard let cid = context.channel?.cid else { return }
                let client = context.client
                client.currentUserController().loadBlockedUsers { result in
                    guard let blockedUsers = try? result.get() else { return }
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
        ]
    }

    private func memberMuteActions(_ context: ChannelActionsContext) -> [DemoAction?] {
        let client = context.client
        let cid = context.cid

        return [
            .item("Mute All Channel Members") { [unowned self] in
                let memberIds = Set(context.channel?.lastActiveMembers.map(\.id) ?? [])
                    .subtracting([client.currentUserId ?? ""])
                guard !memberIds.isEmpty else {
                    self.rootViewController.presentAlert(title: "Channel \(cid) has no other members")
                    return
                }
                client.currentUserController().muteUsers(memberIds) { [unowned self] result in
                    switch result {
                    case .success(let mutedUsers):
                        self.rootViewController.presentAlert(
                            title: "Muted \(mutedUsers.mutes?.count ?? 0) of \(memberIds.count) members",
                            message: mutedUsers.nonExistingUsers.map { "Not found: \($0.joined(separator: ", "))" }
                        )
                    case .failure(let error):
                        self.rootViewController.presentAlert(
                            title: "Couldn't mute the members of channel \(cid)",
                            message: "\(error)"
                        )
                    }
                }
            },
            .item("Unmute All Channel Members") { [unowned self] in
                let memberIds = Set(context.channel?.lastActiveMembers.map(\.id) ?? [])
                    .subtracting([client.currentUserId ?? ""])
                guard !memberIds.isEmpty else {
                    self.rootViewController.presentAlert(title: "Channel \(cid) has no other members")
                    return
                }
                client.currentUserController().unmuteUsers(memberIds) { [unowned self] result in
                    switch result {
                    case .success(let response):
                        self.rootViewController.presentAlert(
                            title: "Unmuted \(memberIds.count) members",
                            message: response.nonExistingUsers.map { "Not found: \($0.joined(separator: ", "))" }
                        )
                    case .failure(let error):
                        self.rootViewController.presentAlert(
                            title: "Couldn't unmute the members of channel \(cid)",
                            message: "\(error)"
                        )
                    }
                }
            }
        ]
    }

    // MARK: - Messages

    private func messagesSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        let channelController = context.channelController
        let client = context.client
        let cid = context.cid

        return [
            DemoActionSection("Send", items: [
                .item("Send message with skip push", isEnabled: context.canSendMessage) { [unowned self] in
                    self.rootViewController.presentAlert(title: "Enter the message text", textFieldPlaceholder: "Send message") { message in
                        guard let message = message, !message.isEmpty else {
                            self.rootViewController.presentAlert(title: "Message is not valid")
                            return
                        }
                        channelController.createNewMessage(text: message, skipPush: true)
                    }
                },
                .item("Send message without url enriching", isEnabled: context.canSendMessage) { [unowned self] in
                    self.rootViewController.presentAlert(title: "Enter the message text", textFieldPlaceholder: "Send message") { message in
                        guard let message = message, !message.isEmpty else {
                            self.rootViewController.presentAlert(title: "Message is not valid")
                            return
                        }
                        channelController.createNewMessage(text: message, skipEnrichUrl: true)
                    }
                },
                .item("Send system message", isEnabled: context.canSendMessage) { [unowned self] in
                    self.rootViewController.presentAlert(title: "Enter the message text", textFieldPlaceholder: "Send message") { message in
                        guard let message = message, !message.isEmpty else {
                            self.rootViewController.presentAlert(title: "Message is not valid")
                            return
                        }
                        channelController.createSystemMessage(text: message)
                    }
                }
            ]),
            DemoActionSection("Restricted Visibility", items: [
                .item("Say Hi to a specific member", isEnabled: context.canSendMessage) { [unowned self] in
                    self.rootViewController.presentAlert(title: "Enter the channel member id", textFieldPlaceholder: "Send message") { userId in
                        guard let userId, !userId.isEmpty,
                              channelController.channel?.lastActiveMembers.map(\.id).contains(userId) == true else {
                            self.rootViewController.presentAlert(title: "user id is not valid")
                            return
                        }
                        channelController.createNewMessage(text: "Hi", restrictedVisibility: [userId])
                    }
                },
                .item("Send and update restricted message", isEnabled: context.canSendMessage) { [unowned self] in
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
                }
            ]),
            DemoActionSection("Navigate", items: [
                .item("Show channel with message id") { [unowned self] in
                    self.rootViewController.presentAlert(
                        title: "Enter message id",
                        textFieldPlaceholder: "Message ID"
                    ) { id in
                        guard let id = id, !id.isEmpty else {
                            self.rootViewController.presentAlert(title: "Message ID is not valid")
                            return
                        }

                        let messageController = client.messageController(cid: cid, messageId: id)
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
                }
            ])
        ]
    }

    // MARK: - Reads & Notifications

    private func readsAndNotificationsSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        let channelController = context.channelController
        let cid = context.cid

        return [
            DemoActionSection(items: [
                .item("Mark channel unread with timestamp") { [unowned self] in
                    self.rootViewController.presentAlert(
                        title: "Mark messages as unread with timestamp",
                        message: "Marks messages as unread from the last number of days",
                        textFieldPlaceholder: "Days"
                    ) { offsetInDaysString in
                        let calendar = Calendar.current
                        guard let offsetInDays = Int(offsetInDaysString ?? ""),
                              let date = calendar.date(byAdding: .day, value: -abs(offsetInDays), to: calendar.startOfDay(for: Date())) else {
                            self.rootViewController.presentAlert(title: "Timestamp offset is not valid")
                            return
                        }
                        channelController.markUnread(from: date) { result in
                            switch result {
                            case .failure(let error):
                                self.rootViewController.presentAlert(title: "Couldn't mark messages as unread \(cid)", message: "\(error)")
                            case .success:
                                break
                            }
                        }
                    }
                },
                .item("Set Channel Push Preferences") { [unowned self] in
                    let pushPreferencesView = PushPreferencesView(
                        onSetPreferences: { level, completion in
                            channelController.setPushPreference(level: level) {
                                completion($0.map(\.level))
                            }
                        },
                        onDisableNotifications: { date, completion in
                            channelController.snoozePushNotifications(until: date) {
                                completion($0.map(\.level))
                            }
                        },
                        onDismiss: { [weak self] in
                            self?.rootViewController.dismiss(animated: true)
                        },
                        initialPreference: channelController.channel?.pushPreference
                    )
                    let hostingController = UIHostingController(rootView: pushPreferencesView)
                    hostingController.title = "Channel Push Preferences - \(cid.id)"

                    self.rootViewController.present(hostingController, animated: true)
                }
            ])
        ]
    }

    // MARK: - Presentation

    private func presentationSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        let cid = context.cid

        return [
            DemoActionSection(items: [
                .item("Change nav bar translucency") { [unowned self] in
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
                },
                .item("Change channel presentation style") { [unowned self] in
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
                },
                .item("Show as Livestream Controller") { [unowned self] in
                    let livestreamController = context.client.livestreamChannelController(for: .init(cid: cid))
                    livestreamController.maxMessageLimitOptions = .recommended
                    livestreamController.countSkippedMessagesWhenPaused = true
                    let vc = DemoLivestreamChatChannelVC()
                    vc.livestreamChannelController = livestreamController
                    vc.hidesBottomBarWhenPushed = true
                    self.rootViewController.navigationController?.pushViewController(vc, animated: true)
                }
            ])
        ]
    }

    // MARK: - Current User & Local Data

    private func currentUserSections(_ context: ChannelActionsContext) -> [DemoActionSection] {
        let client = context.client

        return [
            DemoActionSection(items: [
                .item("Reset User Image") { [unowned self] in
                    client.currentUserController()
                        .updateUserData(unsetProperties: ["image"]) { [unowned self] error in
                            if let error {
                                self.rootViewController.presentAlert(title: error.localizedDescription)
                            }
                        }
                },
                .item("Add a team role for the current user") { [unowned self] in
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
                },
                .item("Delete Downloaded Attachments", isDestructive: true) { [unowned self] in
                    do {
                        let connectedUser = try client.makeConnectedUser()
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
                }
            ])
        ]
    }

    // MARK: - Helpers

    private func presentMemberSelection(
        _ context: ChannelActionsContext,
        didSelect: @escaping (ChatChannelMember) -> Void
    ) {
        let actions = context.channel?.lastActiveMembers.map { member in
            UIAlertAction(title: member.id, style: .default) { _ in
                didSelect(member)
            }
        } ?? []
        rootViewController.presentAlert(title: "Select a member", actions: actions)
    }
}
