//
//  ChatGroupDetailViewModel.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 30/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class ChatGroupDetailViewModel: NSObject {

    // MARK: - Variable
    var channelController: ChatChannelController?
    var screenType: ScreenType = .channelDetail
    var chatMemberController: ChatChannelMemberListController?
    var reloadTable: (() -> Void)?
    var channelMembers: [ChatChannelMember] = []
    var user: ChatChannelMember?

    // MARK: - Enums
    enum ScreenType {
        case channelDetail
        case userdetail
    }

    // MARK: - Initialisers
    override init() {
        super.init()
    }

    /// for channel detail
    init(controller: ChatChannelController) {
        super.init()
        channelController = controller
        screenType = .channelDetail
        initChannelMembers()
    }

    /// for member detail
    init(controller: ChatChannelController, channelMember: ChatChannelMember) {
        super.init()
        channelController = controller
        screenType = .userdetail
        user = channelMember
    }

    func initChannelMembers() {
        guard let controller = channelController else {
            return
        }
        if let channelMemberController = chatMemberController {
            channelMemberController.synchronize { [weak self] error in
                guard let self = self else {
                    return
                }
                self.sortChannelMembers()
            }
        } else {
            do {
                chatMemberController = try ChatClient.shared.memberListController(
                    query: .init(cid: .init(cid: controller.cid?.description ?? "")))
                chatMemberController?.synchronize { [weak self] error in
                    guard let self = self else {
                        return
                    }
                    self.sortChannelMembers()
                }
            } catch {
            }
        }
    }

    private func sortChannelMembers() {
        guard let memberController = chatMemberController else {
            return
        }
        var channelMembers: [ChatChannelMember] = []
        let nonNilUsers = (memberController.members ?? []).filter({ $0.id != nil && $0.name?.isBlank == false })
        if let ownerUser = nonNilUsers.filter({ $0.memberRole == .owner }).first {
            channelMembers.append(ownerUser)
        }
        let filteredUsers = nonNilUsers.filter({ $0.memberRole != .owner })
        let onlineUser = filteredUsers.filter({ $0.isOnline }).sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let offlineUser = filteredUsers.filter({ $0.isOnline == false})
        let alphabetUsers = offlineUser.filter {($0.name?.isFirstCharacterAlp ?? false) == true && $0.isOnline == false}.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let otherUsers = offlineUser.filter {($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
        channelMembers.append(contentsOf: onlineUser)
        channelMembers.append(contentsOf: alphabetUsers)
        channelMembers.append(contentsOf: otherUsers)
        self.channelMembers = channelMembers
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.reloadTable?()
        }
    }
}
