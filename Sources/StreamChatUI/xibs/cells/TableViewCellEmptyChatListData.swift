//
//  TableViewCellEmptyChatListData.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 24/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

public class TableViewCellEmptyChatListData: UITableViewCell {
    static var nib: UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    // MARK: - @IBOutlet
    @IBOutlet private weak var alertImage: UIImageView?
    @IBOutlet private weak var alertText: UILabel!
    // MARK: - View Cycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Methods
    public func configureCell() {
        alertImage?.image = Appearance.Images.systemMagnifying
        alertText.text = "No user matches these keywords..."
    }
}
