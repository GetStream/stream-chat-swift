//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ClampedView_Tests: XCTestCase {
    private lazy var subject: ClampedView! = .init().withoutAutoresizingMaskConstraints
    private lazy var subviewA: UIView! = .init()
    private lazy var subviewB: UIView! = .init()
    private lazy var subviewC: UIView! = .init()

    // MARK: -

    override func setUp() {
        super.setUp()

        subviewA.widthAnchor.constraint(equalToConstant: 100).isActive = true
        subviewB.widthAnchor.constraint(equalToConstant: 300).isActive = true
        subviewC.widthAnchor.constraint(equalToConstant: 50).isActive = true
    }

    // MARK: - appearance

    func test_appearance_containsSubviewsABC_onlyCIsVisible_widthIsEqualToSubviewA() {
        [subviewA, subviewB, subviewC].forEach { subject.addArrangedSubview($0) }
        subviewA.isHidden = true
        subviewB.isHidden = true

        subject.layoutIfNeeded()

        XCTAssertEqual(subject.bounds.width, subviewA.bounds.width)
    }

    func test_appearance_containsSubviewsBC_onlyCIsVisible_widthIsEqualToSubviewB() {
        [subviewB, subviewC].forEach { subject.addArrangedSubview($0) }
        subviewB.isHidden = true

        subject.layoutIfNeeded()

        XCTAssertEqual(subject.bounds.width, subviewB.bounds.width)
    }

    func test_appearance_containsSubviewsC_CIsVisible_widthIsEqualToSubviewC() {
        [subviewC].forEach { subject.addArrangedSubview($0) }

        subject.layoutIfNeeded()

        XCTAssertEqual(subject.bounds.width, subviewC.bounds.width)
    }
}
