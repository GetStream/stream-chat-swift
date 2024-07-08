//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
import StreamChatUI
import StreamSwiftTestHelpers
import SwiftUI
import XCTest

final class ChatChannelAvatarView_SwiftUI_Tests: XCTestCase {
    func test_injectedSwiftUIView() {
        struct CustomChatChannelAvatarView: ChatChannelAvatarView.SwiftUIView {
            @ObservedObject var dataSource: ChatChannelAvatarView.ObservedObject<Self>

            init(dataSource: ChatChannelAvatarView.ObservedObject<Self>) {
                self.dataSource = dataSource
            }

            var body: some View {
                Image(url: dataSource.content.channel!.imageURL!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                    .mask(Circle())
            }
        }

        let channel = ChatChannel.mock(
            cid: .unique,
            imageURL: TestImages.yoda.url
        )

        let view = ChatChannelAvatarView.SwiftUIWrapper<CustomChatChannelAvatarView>()
        view.content = (channel, nil)
        view.addSizeConstraints()

        AssertSnapshot(view)
    }
}

private extension UIView {
    func addSizeConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            widthAnchor.constraint(equalToConstant: 50)
        ])
    }
}
