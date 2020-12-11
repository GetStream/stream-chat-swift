//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerSuggestionsCollectionView<ExtraData: ExtraDataTypes>: UICollectionView,
    UIConfigProvider,
    AppearanceSetting,
    Customizable {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }

        setUp()
        (self as! Self).applyDefaultAppearance()
        setUpAppearance()
        setUpLayout()
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

    public func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.generalBackground
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bounces = false
        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = 10
    }
    
    public func setUp() {}

    public func setUpAppearance() {}

    public func setUpLayout() {}

    public func updateContent() {}
}
