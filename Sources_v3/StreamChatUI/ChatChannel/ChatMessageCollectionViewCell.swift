//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

protocol ChatMessageCollectionViewCellDelegate: class {}

open class ChatMessageCollectionViewCell: UICollectionViewCell {
    weak var delegate: ChatMessageCollectionViewCellDelegate?
}
