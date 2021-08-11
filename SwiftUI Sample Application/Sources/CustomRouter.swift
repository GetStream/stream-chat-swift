//
// Created by kojiba on 11.08.2021.
//

import Foundation
import StreamChat
import StreamChatUI

class CustomRouter: ChatChannelListRouter {

    var showCurrentUserProfileClosure: () -> Void = {}
    var showMessageListClosure: (ChannelId) -> Void = {_ in }
    var didTapMoreButtonClosure: (ChannelId) -> Void = {_ in }
    var didTapDeleteButtonClosure: (ChannelId) -> Void = {_ in }

    override func showCurrentUserProfile() {
        showCurrentUserProfileClosure()
    }

    override func showMessageList(for cid: ChannelId) {
        showMessageListClosure(cid)
    }

    override func didTapMoreButton(for cid: ChannelId) {
        didTapMoreButtonClosure(cid)
    }

    override func didTapDeleteButton(for cid: ChannelId) {
        didTapDeleteButtonClosure(cid)
    }
}
