//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

final class ChannelListVC: ChatChannelListVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let query = ChannelListQuery.init(filter: .containMembers(userIds: [ChatClient.shared.currentUserId!]))
        self.controller = ChatClient.shared.channelListController(query: query)
    }
}
