//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
final class QuotedChatMessageView_SwiftUI_Tests: XCTestCase {
    func test_injectedSwiftUIView() {
        struct CustomQuotedChatMessageView: QuotedChatMessageView.SwiftUIView {
            @ObservedObject var dataSource: QuotedChatMessageView.ObservedObject<Self>

            init(dataSource: QuotedChatMessageView.ObservedObject<Self>) {
                self.dataSource = dataSource
            }

            var body: some View {
                HStack {
                    Image(url: dataSource.content!.message.author.imageURL!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                        .mask(Circle())
                        .frame(width: 20, height: 20, alignment: .leading)
                    Text(dataSource.content!.message.text)
                        .foregroundColor(.primary)
                        .font(.system(size: 10))
                        .padding(4)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(9)
                }
            }
        }

        let view = QuotedChatMessageView.SwiftUIWrapper<CustomQuotedChatMessageView>()
        view.content = QuotedChatMessageView.Content(
            message: .mock(
                id: .unique,
                cid: .unique,
                text: "Hello World!",
                author: .mock(id: .unique, imageURL: .localYodaImage)
            ),
            avatarAlignment: .leading
        )
        view.backgroundColor = UIColor.white

        AssertSnapshot(view, variants: [SnapshotVariant.defaultLight], size: .init(width: 100, height: 60))
    }
}
