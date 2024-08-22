//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The poll results option section header view.
open class PollResultsSectionHeaderView: _TableHeaderFooterView, ThemeProvider {
    public struct Content {
        public var option: PollOption
        public var poll: Poll

        public init(option: PollOption, poll: Poll) {
            self.option = option
            self.poll = poll
        }
    }

    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The poll option view displayed in the section header of the poll results.
    open private(set) lazy var optionView: PollResultsSectionHeaderOptionView = components
        .pollResultsSectionHeaderOptionView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(optionView, insets: .init(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    override open func updateContent() {
        super.updateContent()

        guard let content = self.content else { return }
        optionView.content = .init(option: content.option, poll: content.poll)
    }
}