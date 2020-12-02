//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

public struct ChatChannelCollectionViewLayoutModel {
    public var forWidth: CGFloat
    public var itemHeights: [CGFloat]

    public static let zero = ChatChannelCollectionViewLayoutModel(forWidth: 0, itemHeights: [])
}

public protocol ChatChannelCollectionViewLayoutDelegate: AnyObject {
    func createLayoutModel() -> ChatChannelCollectionViewLayoutModel
}

open class ChatChannelCollectionViewLayout: UICollectionViewLayout {
    var layoutModel: ChatChannelCollectionViewLayoutModel = .zero
    var contentSize: CGSize = .zero
    var attributes: [UICollectionViewLayoutAttributes] = []
    var interItemSpacing: CGFloat = 8

    open weak var delegate: ChatChannelCollectionViewLayoutDelegate?

    // MARK: - Lifecycle

    override public required init() {
        super.init()
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {}

    // MARK: - Layout

    override open var collectionViewContentSize: CGSize { contentSize }

    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        layoutModel.forWidth != newBounds.width
    }

    override open func prepare() {
        super.prepare()
        guard let delegate = delegate else { return }
        layoutModel = delegate.createLayoutModel()
        let width = layoutModel.forWidth
        var offset: CGFloat = 0
        var attributes: [UICollectionViewLayoutAttributes] = []
        // latest message has ip = {0;0}, but must be bottom one, so we iterate in reverse order
        for (idx, height) in layoutModel.itemHeights.enumerated().reversed() {
            let attribute = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: idx, section: 0))
            attribute.frame = CGRect(x: 0, y: offset, width: width, height: height)
            attributes.append(attribute)
            offset += height
            if idx > 0 {
                offset += interItemSpacing
            }
        }
        // attributes are added from old message to new message, need to reverse it to achieve
        // `attributes[idx].indexPath.item == idx`
        self.attributes = attributes.reversed()
        contentSize = CGSize(width: width, height: offset)
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        attributes.filter { $0.frame.intersects(rect) }
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        attributes[indexPath.item]
    }
}
