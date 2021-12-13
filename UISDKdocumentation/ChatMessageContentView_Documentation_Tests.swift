//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class ChatMessageContentView_Documentation_Tests: XCTestCase {

    func test_generateDocsSnapshot() {
        // Create a view to annotate and create documentation for.
        let view = ChatMessageContentView().withoutAutoresizingMaskConstraints

        view.layoutOptions = [
            .bubble,
            .avatarSizePadding,
            .timestamp,
            .text,
            .avatar,
            .authorName,
            .reactions,
            .threadInfo
        ]

        view.content = .mock(
            id: .unique,
            cid: .unique,
            text: "Hello World!",
            type: .regular,
            author: .mock(id: .unique, name: "John Doe", imageURL: TestImages.yoda.url),
            command: nil,
            createdAt: .unique,
            locallyCreatedAt: nil,
            updatedAt: .unique,
            deletedAt: nil,
            arguments: nil,
            parentMessageId: nil,
            quotedMessage: nil,
            showReplyInChannel: false,
            replyCount: 3,
            extraData: [:],
            isSilent: false,
            isShadowed: false,
            reactionScores: ["like": 2],
            reactionCounts: ["like": 2],
            mentionedUsers: Set<ChatUser>(),
            threadParticipants: [.mock(id: .unique, imageURL: TestImages.vader.url)],
            attachments: [],
            latestReplies: [],
            localState: .pendingSend,
            isFlaggedByCurrentUser: false,
            latestReactions: Set<ChatMessageReaction>(),
            currentUserReactions: Set<ChatMessageReaction>(),
            isSentByCurrentUser: false,
            pinDetails: nil
        )

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 300),
            view.heightAnchor.constraint(equalToConstant: 100),
        ])

        generateDocs(
            for: view,
            annotations: { view in
                [
                    .init(view: view.mainContainer, descriptionLabelPosition: .topLeft),
                    .init(view: view.authorAvatarView!, descriptionLabelPosition: .bottomLeft),
                    .init(view: view.reactionsBubbleView!, descriptionLabelPosition: .topRight),
                    .init(view: view.bubbleThreadMetaContainer, descriptionLabelPosition: .bottomRight),
                    .init(view: view.bubbleView!, lineColor: .systemTeal, descriptionLabelPosition: .top),
                    .init(view: view.metadataContainer!, lineColor: .systemTeal, descriptionLabelPosition: .bottom),
                    .init(view: view.threadInfoContainer!, lineColor: .systemTeal, descriptionLabelPosition: .right),
                 ]
            },
            name: "ChatMessageContentView_documentation",
            variants: [.defaultLight],
            containerBorderWidth: 0
        )
    }

}
