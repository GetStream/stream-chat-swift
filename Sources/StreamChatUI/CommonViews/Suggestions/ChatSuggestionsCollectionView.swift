//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The collection view of the suggestions view controller.
open class ChatSuggestionsCollectionView: UICollectionView,
    ThemeProvider,
    Customizable {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }

        setUp()
        setUpLayout()
        setUpAppearance()
        updateContent()
    }

    // MARK: - Init

    public required init(layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Appearance
    
    public func setUp() {}

    public func setUpAppearance() {
        backgroundColor = appearance.colorPalette.popoverBackground
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bounces = true
        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = 10
    }

    public func setUpLayout() {}

    public func updateContent() {}
}
