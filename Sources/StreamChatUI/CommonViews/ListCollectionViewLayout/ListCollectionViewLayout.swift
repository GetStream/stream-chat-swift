//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The `ListCollectionViewLayout` delegate to control how to display the list.
public protocol ListCollectionViewLayoutDelegate: UICollectionViewDelegate {
    /// Implement this method to have detailed control over the visibility of the cell separators.
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: ListCollectionViewLayout,
        shouldShowSeparatorForCellAtIndexPath indexPath: IndexPath
    ) -> Bool
}

/// An `UICollectionViewFlowLayout` implementation to make the collection view behave as a `UITableView`.
open class ListCollectionViewLayout: UICollectionViewFlowLayout {
    /// The kind identifier of the cell separator view.
    open class var separatorKind: String {
        "CellSeparator"
    }

    /// The height of the cell separator view. This changes the `minimumLineSpacing` to properly display the separator height.
    /// By default it is the hair height, one physical pixel (1 / displayScale). If a value is set, it will change the default.
    /// The changes will apply after the layout it has been invalidated.
    open var separatorHeight: CGFloat?

    override open func prepare() {
        super.prepare()

        let defaultSeparatorHeight = 1 / (collectionView?.traitCollection.displayScale ?? 1)
        minimumLineSpacing = separatorHeight ?? defaultSeparatorHeight

        // We should always propose the full width of the collection view for the cell width
        estimatedItemSize = .init(
            width: collectionView?.bounds.width ?? 0,
            height: estimatedItemSize.height
        )
    }
    
    /// Partly taken from: https://github.com/Instagram/IGListKit/issues/571#issuecomment-386960195
    override open func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if let indexPaths = context.invalidatedItemIndexPaths {
            context.invalidateSupplementaryElements(
                ofKind: Self.separatorKind,
                at: indexPaths
            )
        }
        super.invalidateLayout(with: context)
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let cellAttributes = super.layoutAttributesForElements(in: rect) ?? []
        let separatorAttributes = separatorLayoutAttributes(forCellLayoutAttributes: cellAttributes)
        return cellAttributes + separatorAttributes
    }

    private func separatorLayoutAttributes(
        forCellLayoutAttributes cellAttributes: [UICollectionViewLayoutAttributes]
    ) -> [UICollectionViewLayoutAttributes] {
        guard let collectionView = collectionView else { return [] }
        let delegate = collectionView.delegate as? ListCollectionViewLayoutDelegate
        return cellAttributes.compactMap { cellAttribute in

            // Check if the delegate explicitly returns `false` otherwise assume the separator should be shown
            guard delegate?.collectionView(
                collectionView,
                layout: self,
                shouldShowSeparatorForCellAtIndexPath: cellAttribute.indexPath
            ) ?? true else { return nil }

            let separatorAttribute = UICollectionViewLayoutAttributes(
                forSupplementaryViewOfKind: Self.separatorKind,
                with: cellAttribute.indexPath
            )

            let cellFrame = cellAttribute.frame

            separatorAttribute.frame = CGRect(
                x: cellFrame.origin.x,
                y: cellFrame.origin.y + cellFrame.size.height,
                width: cellFrame.size.width,
                height: minimumLineSpacing
            )

            return separatorAttribute
        }
    }
}
