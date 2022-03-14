//
//  TableViewHeaderCreateChat.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 22/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class TableViewHeaderCreateChat: UITableViewCell {
    // MARK: - VARIBALES
    static let reuseID = "TableViewHeaderCreateChat"
    var bCallbackGroupCreate: (() -> Void)?
    var bCallbackGroupSelect: (() -> Void)?
    var bCallbackGroupWeHere: (() -> Void)?
    var bCallbackGroupJoinViaQR: (() -> Void)?
    // MARK: - OUTLETS
    @IBOutlet weak var labelSortingType: UILabel!
    // MARK: - Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    // MARK: - Actions
    @IBAction func createGroupAction(_ sender: UIButton) {
        self.bCallbackGroupCreate?()
    }
    @IBAction func selectGroupAction(_ sender: UIButton) {
        self.bCallbackGroupSelect?()
    }
    @IBAction func weHereGroupAction(_ sender: UIButton) {
        self.bCallbackGroupWeHere?()
    }
    @IBAction func joinViaQRGroupAction(_ sender: UIButton) {
        self.bCallbackGroupJoinViaQR?()
    }
}
