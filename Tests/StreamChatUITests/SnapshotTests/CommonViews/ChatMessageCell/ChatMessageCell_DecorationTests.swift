//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageCell_DecorationTests: XCTestCase {
    private lazy var subject: ChatMessageCell! = .init(style: .default, reuseIdentifier: nil)

    override func setUpWithError() throws {
        try super.setUpWithError()
        subject.setMessageContentIfNeeded(
            contentViewClass: ChatMessageContentView.self,
            attachmentViewInjectorType: nil,
            options: [.bubble]
        )

        subject.setUpLayout()

        subject.frame = .init(x: 0, y: 0, width: 100, height: 200)
        subject.setNeedsLayout()
        subject.layoutIfNeeded()
    }

    override func tearDownWithError() throws {
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - setupLayout

    func test_setupLayout_headerAndFooterContainersAreNotInHierarchy() {
        XCTAssertEqual(subject.containerStackView.subviews.count, 1)
    }

    func test_setupLayout_messageContentViewHasSameWidthAsTheCell() {
        XCTAssertEqual(100, subject.messageContentView?.frame.size.width)
    }

    // MARK: - setUpAppearance

    func test_setUpAppearance_configuresHeaderAndFooterContainersCorrectly() {
        subject.headerContainerView.backgroundColor = .red
        subject.footerContainerView.backgroundColor = .red

        subject.setUpAppearance()

        XCTAssertNil(subject.headerContainerView.backgroundColor)
        XCTAssertNil(subject.footerContainerView.backgroundColor)
    }

    // MARK: - prepareForReuse

    func test_prepareForReuse_configuresHeaderAndFooterContainersCorrectly() {
        subject.contentView.addSubview(subject.headerContainerView)
        subject.contentView.addSubview(subject.footerContainerView)

        subject.prepareForReuse()

        XCTAssertNil(subject.headerContainerView.superview)
        XCTAssertNil(subject.footerContainerView.superview)
    }

    // MARK: - updateDecoration

    func test_updateDecoration_decorationTypeIsHeaderAndDecorationViewIsNotNil_updatesHeaderContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.updateDecoration(for: .header, decorationView: decorationView)

        XCTAssertEqual(subject.headerContainerView.subviews.count, 1)
        XCTAssertEqual(subject.headerContainerView.subviews.first, decorationView)
        XCTAssertEqual(subject.headerContainerView.superview, subject.containerStackView)
        XCTAssertEqual(subject.headerContainerView, subject.containerStackView.arrangedSubviews.first)
    }

    func test_updateDecoration_decorationTypeIsHeaderAndDecorationViewIsNotNilAndLaterUpdateWithDecorationViewNil_updatesHeaderContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.updateDecoration(for: .header, decorationView: decorationView)
        subject.updateDecoration(for: .header, decorationView: nil)

        XCTAssertNil(subject.headerContainerView.superview)
    }

    func test_updateDecoration_decorationTypeIsFooterAndDecorationViewIsNotNil_updatesFooterContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.updateDecoration(for: .footer, decorationView: decorationView)

        XCTAssertEqual(subject.footerContainerView.subviews.count, 1)
        XCTAssertEqual(subject.footerContainerView.subviews.first, decorationView)
        XCTAssertEqual(subject.footerContainerView.superview, subject.containerStackView)
        XCTAssertEqual(subject.footerContainerView, subject.containerStackView.arrangedSubviews.last)
    }

    func test_updateDecoration_decorationTypeIsFooterAndDecorationViewIsNotNilAndLaterUpdateWithDecorationViewNil_updatesFooterContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.updateDecoration(for: .footer, decorationView: decorationView)
        subject.updateDecoration(for: .footer, decorationView: nil)

        XCTAssertNil(subject.footerContainerView.superview)
    }
}
