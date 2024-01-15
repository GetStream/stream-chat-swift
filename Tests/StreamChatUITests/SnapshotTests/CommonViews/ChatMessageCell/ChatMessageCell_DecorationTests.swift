//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageCell_DecorationTests: XCTestCase {
    private final class MockDecorationView: ChatMessageDecorationView {}

    private lazy var subject: ChatMessageCell! = .init(style: .default, reuseIdentifier: nil)

    override func setUp() {
        super.setUp()
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

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - spacingBetween

    func test_spacingBetween_returnsExpectedValue() {
        XCTAssertEqual(subject.spacingBetween, 8)
    }

    func test_spacingBetween_willUpdateTheLayout() {
        let mockHeader = MockDecorationView()
        let mockFooter = MockDecorationView()
        let spyHeaderContainerView = SpyUIView()
        let spyFooterContainerView = SpyUIView()
        subject.headerContainerView = spyHeaderContainerView
        subject.footerContainerView = spyFooterContainerView
        subject.setDecoration(for: .header, decorationView: mockHeader)
        subject.setDecoration(for: .footer, decorationView: mockFooter)

        spyHeaderContainerView.embedWasCalledWith = nil
        spyFooterContainerView.embedWasCalledWith = nil
        subject.spacingBetween = 10

        XCTAssertEqual(spyHeaderContainerView.embedWasCalledWith?.insets, .init(top: 0, leading: 0, bottom: 10, trailing: 0))
        XCTAssertEqual(spyFooterContainerView.embedWasCalledWith?.insets, .init(top: 10, leading: 0, bottom: 0, trailing: 0))
    }

    // MARK: - setupLayout

    func test_setupLayout_headerAndFooterContainersAreInHierarchy() {
        XCTAssertEqual(subject.containerStackView.subviews.count, 3)
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

        XCTAssertTrue(subject.headerContainerView.subviews.isEmpty)
        XCTAssertTrue(subject.headerContainerView.isHidden)
        XCTAssertTrue(subject.footerContainerView.subviews.isEmpty)
        XCTAssertTrue(subject.footerContainerView.isHidden)
    }

    // MARK: - setDecoration

    func test_setDecoration_decorationTypeIsHeaderAndDecorationViewIsNotNil_setsHeaderContainerAsExpected() {
        let decorationView = MockDecorationView()

        subject.setDecoration(for: .header, decorationView: decorationView)

        XCTAssertEqual(subject.headerContainerView.subviews.count, 1)
        XCTAssertEqual(subject.headerContainerView.subviews.first, decorationView)
        XCTAssertEqual(subject.headerContainerView.superview, subject.containerStackView)
        XCTAssertFalse(subject.headerContainerView.isHidden)
    }

    func test_setDecoration_decorationTypeIsHeaderAndDecorationViewIsNotNilAndLaterSetWithDecorationViewNil_setsHeaderContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.setDecoration(for: .header, decorationView: decorationView)
        subject.setDecoration(for: .header, decorationView: nil)

        XCTAssertTrue(subject.headerContainerView.isHidden)
    }

    func test_setDecoration_decorationTypeIsFooterAndDecorationViewIsNotNil_setsFooterContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.setDecoration(for: .footer, decorationView: decorationView)

        XCTAssertEqual(subject.footerContainerView.subviews.count, 1)
        XCTAssertEqual(subject.footerContainerView.subviews.first, decorationView)
        XCTAssertEqual(subject.footerContainerView.superview, subject.containerStackView)
        XCTAssertFalse(subject.footerContainerView.isHidden)
    }

    func test_setDecoration_decorationTypeIsFooterAndDecorationViewIsNotNilAndLaterUpdateWithDecorationViewNil_setsFooterContainerAsExpected() {
        final class MockDecorationView: ChatMessageDecorationView {}
        let decorationView = MockDecorationView()

        subject.setDecoration(for: .footer, decorationView: decorationView)
        subject.setDecoration(for: .footer, decorationView: nil)

        XCTAssertTrue(subject.footerContainerView.isHidden)
    }
}

// MARK: - Private Helpers

private final class SpyUIView: UIView, Spy {
    var recordedFunctions: [String] = []
    var embedWasCalledWith: (subView: UIView, insets: NSDirectionalEdgeInsets)?

    override func embed(
        _ subview: UIView,
        insets: NSDirectionalEdgeInsets = .zero
    ) {
        embedWasCalledWith = (subview, insets)
        super.embed(subview, insets: insets)
    }
}
