//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
class ChatChannelListItemView_SwiftUI_Tests: XCTestCase {
    func test_injectedSwiftUIView() {
        struct CustomChannelListItemView: ChatChannelListItemView.SwiftUIView {
            @ObservedObject var dataSource: ChatChannelListItemView.ObservedObject<Self>
            
            public init(dataSource: ChatChannelListItemView.ObservedObject<Self>) {
                self.dataSource = dataSource
            }

            public var body: some View {
                HStack {
                    Image(url: dataSource.content!.channel.imageURL!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                        .mask(Circle())
                        .frame(width: 50, height: 50)

                    Spacer()

                    Text(dataSource.content!.channel.name!)
                }.padding()
            }
        }

        let channel = ChatChannel.mock(
            cid: .unique,
            name: "Channel 1",
            imageURL: TestImages.yoda.url,
            lastMessageAt: .init(timeIntervalSince1970: 1_611_951_526_000)
        )

        let view = ChatChannelListItemView.SwiftUIWrapper<CustomChannelListItemView>()
        view.content = .init(channel: channel, currentUserId: nil)
        view.addWidthConstraint()

        AssertSnapshot(view)
    }
}

private extension UIView {
    func addWidthConstraint() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 350)
        ])
    }
}

@available(iOS 13.0, *)
extension Image {
    init(url: URL) {
        let uiImage = UIImage(data: try! Data(contentsOf: url))!
        self = Image(uiImage: uiImage)
    }
}
