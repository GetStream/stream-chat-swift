//
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class CellSeparatorCollectionViewLayout<ExtraData: ExtraDataTypes>: UICollectionViewFlowLayout {

    open var lineHeight: CGFloat = 0.5

    override public init() {
        super.init()
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    open func commonInit() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = lineHeight
        register(CellSeparatorView<ExtraData>.self, forDecorationViewOfKind: CellSeparatorView<ExtraData>.reuseId)
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect) ?? []
        let lineHeight = self.minimumLineSpacing

        var decorationAttributes: [UICollectionViewLayoutAttributes] = []

        for layoutAttribute in layoutAttributes where layoutAttribute.indexPath.item > 0 {
            let separatorAttribute = UICollectionViewLayoutAttributes(
                forDecorationViewOfKind: CellSeparatorView<ExtraData>.reuseId,
                with: layoutAttribute.indexPath
            )
            let cellFrame = layoutAttribute.frame
            separatorAttribute.frame = CGRect(
                x: cellFrame.origin.x,
                y: cellFrame.origin.y - lineHeight,
                width: cellFrame.size.width,
                height: lineHeight
            )
            separatorAttribute.zIndex = Int.max
            decorationAttributes.append(separatorAttribute)
        }

        return layoutAttributes + decorationAttributes
    }
}
