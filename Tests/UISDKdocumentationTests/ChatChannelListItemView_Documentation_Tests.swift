//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class ChatChannelListItemView_Documentation_Tests: XCTestCase {
    // Example of usage for generating UISDK documentation:
    
    func test_generateDocs_example_channelListItemView_namedLabelsWithPointers() {
        // Create a view to annotate and create documentation for.
        let view = ChatChannelListItemView().withoutAutoresizingMaskConstraints
        
        // Create the necessary datasource and assign it to the view.
        let channel = ChatChannel.documentationMock(cid: .unique, unreadCount: .mock(messages: 10))
        view.content = .init(channel: channel, currentUserId: nil)
        
        // Generate the docs for the given view:
        generateDocs(
            for: view, // The whole view which we want to annotate
            annotations: { view in
                [ // Annotation types for the given subviews of the view
                    .init(view: view.titleLabel, descriptionLabelPosition: .top),
                    .init(view: view.subtitleLabel, descriptionLabelPosition: .bottom),
                    .init(view: view.avatarView, descriptionLabelPosition: .left),
                    .init(view: view.timestampLabel, descriptionLabelPosition: .bottomRight),
                    .init(view: view.unreadCountView, descriptionLabelPosition: .topRight),
                    .init(view: view.topContainer, highlightColor: .purple, isNameIncluded: false, descriptionLabelPosition: nil),
                    .init(view: view.bottomContainer, highlightColor: .purple, isNameIncluded: false, descriptionLabelPosition: nil)
                ]
            },
            name: "ChannelListItemView_documentation", // Name of the file, will be suffixed with dark/light trait...
            variants: .onlyUserInterfaceStyles
        )
    }
}
