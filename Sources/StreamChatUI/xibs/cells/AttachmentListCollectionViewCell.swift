//
//  AttachmentListCollectionViewCell.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 10/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

public class AttachmentListCollectionViewCell: UICollectionViewCell {

    public static let reuseID = "AttachmentListCollectionViewCell"
    
    @IBOutlet public weak var attachmentImageView: UIImageView!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
