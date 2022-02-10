//
//  ContextMenuCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 10/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class ContextMenuCell: UITableViewCell {
    
    static let identifier = "ContextMenuCell"

    @IBOutlet open weak var titleLabel: UILabel!
    @IBOutlet open weak var iconImageView: UIImageView!
    @IBOutlet open weak var separator: UILabel!

    weak var contextMenu: ContextMenu?
    weak var tableView: UITableView?
    var item: ContextMenuItem!
    var style : ContextMenuConstants? = nil
    
    override open func awakeFromNib() {
        super.awakeFromNib()
    }

    override open func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.contentView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        }else{
            self.contentView.backgroundColor = .clear
        }
    }
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        
        if let label = self.titleLabel {
            label.text = nil
        }
        if let imgView = self.iconImageView {
            imgView.image = nil
        }
        
    }
    
    open func setup(){
        if let label = self.titleLabel {
            label.text = item.title
            if let menuConstants = style {
                label.textColor = menuConstants.LabelDefaultColor
                label.font = menuConstants.LabelDefaultFont
            }
        }
        if let imgView = self.iconImageView {
            imgView.image = item.image
            imgView.isHidden = (item.image == nil)
        }
    }
    
}
