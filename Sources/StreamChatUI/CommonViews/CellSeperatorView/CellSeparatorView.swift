//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class CellSeparatorView<ExtraData: ExtraDataTypes>: UICollectionReusableView, UIConfigProvider {

    /// The reuse identifier of the reusable header view.
    open class var reuseId: String { String(describing: self) }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = uiConfig.colorPalette.border
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override open func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        self.frame = layoutAttributes.frame
    }
}
