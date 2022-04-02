//
//  TableViewHeaderAlphabetSection.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 23/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class TableViewHeaderAlphabetSection: UITableViewHeaderFooterView {
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    static var identifier: String {
        return String(describing: self)
    }
    // MARK: - @IBOutlet
    @IBOutlet public weak var lblTitle: UILabel!
    @IBOutlet public weak var titleContainerView: UIView!
}
