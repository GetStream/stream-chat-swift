//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The collection view of the suggestions view controller.
internal typealias ChatMessageComposerSuggestionsCollectionView = _ChatMessageComposerSuggestionsCollectionView<NoExtraData>

/// The collection view of the suggestions view controller.
internal class _ChatMessageComposerSuggestionsCollectionView<ExtraData: ExtraDataTypes>: UICollectionView,
    UIConfigProvider,
    AppearanceSetting,
    Customizable {
    override internal func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }

        setUp()
        setUpLayout()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        updateContent()
    }

    // MARK: - Init

    internal required init(layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
    }

    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Appearance

    internal func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.popoverBackground
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bounces = true
        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = 10
    }
    
    internal func setUp() {}

    internal func setUpAppearance() {}

    internal func setUpLayout() {}

    internal func updateContent() {}
}
