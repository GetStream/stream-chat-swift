//
//  TableViewHeaderChatUserList.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 04/02/22.
//

import UIKit

public class TableViewHeaderChatUserList: UITableViewCell {
    //
    public static let reuseId: String = "TableViewHeaderChatUserList"
    //
    @IBOutlet public weak var lblTitle: UILabel!
    @IBOutlet public weak var titleContainerView: UIView!
    //
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
