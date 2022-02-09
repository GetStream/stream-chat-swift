//
//  TableViewHeaderChatUserList.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 04/02/22.
//

import UIKit
import SwiftUI

public class TableViewHeaderChatUserList: UITableViewCell {
    //
    static let reuseId: String = "TableViewHeaderChatUserList"
    //
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var titleContainerView: UIView!
    //
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
