//
// Created by kojiba on 11.08.2021.
//

import Foundation
import StreamChat
import StreamChatUI

class CustomRouter: ChatChannelListRouter {

    // TODO: this is a very bad spike/hack
    static var showCurrentUserProfileClosure: () -> Void = {}
    static var showMessageListClosure: (ChannelId) -> Void = {_ in }
    static var didTapMoreButtonClosure: (ChannelId) -> Void = {_ in }
    static var didTapDeleteButtonClosure: (ChannelId) -> Void = {_ in }

    override func showCurrentUserProfile() {
        CustomRouter.showCurrentUserProfileClosure()
    }

    override func showMessageList(for cid: ChannelId) {
        CustomRouter.showMessageListClosure(cid)
    }

    override func didTapMoreButton(for cid: ChannelId) {
        CustomRouter.didTapMoreButtonClosure(cid)
    }

    override func didTapDeleteButton(for cid: ChannelId) {
        CustomRouter.didTapDeleteButtonClosure(cid)
    }
}
