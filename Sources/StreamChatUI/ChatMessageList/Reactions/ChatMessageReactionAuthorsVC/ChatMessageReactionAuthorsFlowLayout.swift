//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// The default `ChatMessageReactionAuthorsVC` collection view flow layout.
/// It manipulates the cell attributes so that each row is centred.
open class ChatMessageReactionAuthorsFlowLayout: UICollectionViewFlowLayout {
    override public required init() {
        super.init()
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        sectionInsetReference = .fromSafeArea
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superLayoutAttributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        // copying is required to avoid UICollectionViewFlowLayout cache mismatched frame
        let layoutAttributes = superLayoutAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }

        guard scrollDirection == .vertical else {
            return layoutAttributes
        }

        let cellLayoutAttributes = layoutAttributes.filter { $0.representedElementCategory == .cell }

        // Group cell attributes by row (all cells in the same row have the same Y axis)
        let rowCellAttributes = Dictionary(
            grouping: cellLayoutAttributes,
            by: { $0.center.y }
        )

        for attributes in rowCellAttributes.values {
            // Get the total width of the cells on the same row
            let allCellsWidth = attributes.reduce(CGFloat(0)) { (partialWidth, attribute) -> CGFloat in
                partialWidth + attribute.size.width
            }

            let collectionViewWidth = collectionView?.safeAreaLayoutGuide.layoutFrame.width ?? 0
            let allCellsSpacing = minimumInteritemSpacing * CGFloat(attributes.count - 1)
            let totalInset = collectionViewWidth - allCellsWidth - allCellsSpacing - sectionInset.left - sectionInset.right

            // Loop each cell to adjust the cell's origin and prepare leftInset for the next cell
            var leftInset = (totalInset / 2).rounded(.down) + sectionInset.left
            for attribute in attributes {
                attribute.frame.origin.x = leftInset
                leftInset = attribute.frame.maxX + minimumInteritemSpacing
            }
        }

        return layoutAttributes
    }
}
