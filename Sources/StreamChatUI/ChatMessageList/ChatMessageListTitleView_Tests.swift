//
//  ChatMessageListTitleView_Tests.swift
//  StreamChatTests
//
//  Created by Lukáš Hromadník on 25.03.2021.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatUI
import XCTest

private typealias ChatMessageListTitleView = _ChatMessageListTitleView<NoExtraData>

final class ChatMessageListTitleView_Tests: XCTestCase {
    func test_emptyAppearance() {
        let view = ChatMessageListTitleView().withoutAutoresizingMaskConstraints
        NSLayoutConstraint.activate([
            view.widthAnchor.pin(equalToConstant: 320),
            view.heightAnchor.pin(equalToConstant: 44)
        ])
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = ChatMessageListTitleView().withoutAutoresizingMaskConstraints
        view.content = ("Title", "Subtitle")
        NSLayoutConstraint.activate([
            view.widthAnchor.pin(equalToConstant: 320),
            view.heightAnchor.pin(equalToConstant: 44)
        ])
        AssertSnapshot(view)
    }
    
    func test_defaultAppearanceWithoutTitle() {
        let view = ChatMessageListTitleView().withoutAutoresizingMaskConstraints
        view.content = (nil, "Subtitle")
        NSLayoutConstraint.activate([
            view.widthAnchor.pin(equalToConstant: 320),
            view.heightAnchor.pin(equalToConstant: 44)
        ])
        AssertSnapshot(view)
    }
    
    func test_defaultAppearanceWithoutSubtitle() {
        let view = ChatMessageListTitleView().withoutAutoresizingMaskConstraints
        view.content = ("Title", nil)
        NSLayoutConstraint.activate([
            view.widthAnchor.pin(equalToConstant: 320),
            view.heightAnchor.pin(equalToConstant: 44)
        ])
        AssertSnapshot(view)
    }
    
    func test_customAppearance() {
        class CustomTitleView: ChatMessageListTitleView { }
        CustomTitleView.defaultAppearance.addRule {
            $0.titleLabel.textColor = .red
            $0.subtitleLabel.textColor = .blue
        }
        let view = CustomTitleView().withoutAutoresizingMaskConstraints
        view.content = ("Red", "Blue")
        NSLayoutConstraint.activate([
            view.widthAnchor.pin(equalToConstant: 320),
            view.heightAnchor.pin(equalToConstant: 44)
        ])
        AssertSnapshot(view)
    }
}
