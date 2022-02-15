//
//  ChatMessageTVCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 08/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

public enum AdminMessageType: String {
    case daoAddInitialSigners
    case none
}

class AdminMessageTVCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var lblTime: UILabel!

    // MARK: - Variables
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()

    // MARK: - View life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    // MARK: - Functions
    func configCell() {
        if let createdAt = content?.createdAt {
            lblTime.text = dateFormatter.string(from: createdAt)
        } else {
            lblTime.text = nil
        }
        switch content?.extraData.adminMessageType {
        case .daoAddInitialSigners:
            lblDesc.text = getInitialAddSignerDesc()
        default:
            lblDesc.text = ""
        }
    }
    
    func configCell(with date: Date?, message: String) {
        if let createdAt = date {
            lblTime.text = dateFormatter.string(from: createdAt)
        } else {
            lblTime.text = nil
        }
        lblDesc.text = message
    }

    private func getInitialAddSignerDesc() -> String {
        var descText = ""
        if content?.isSentByCurrentUser ?? false {
            descText.append("You ")
        } else {
            descText.append("\(content?.author.name ?? "-") ")
        }
        descText.append("created this group ")
        let otherAdmins = content?.extraData.daoAdmins.filter({ ($0["signerUserId"] as? String ?? "") != ChatClient.shared.currentUserId }) ?? [[String: Any]]()
        if otherAdmins.count >= 1 {
            descText.append("with ")
            descText.append(otherAdmins.first?["signerName"] as? String ?? "")
        }
        if otherAdmins.count >= 2 {
            descText.append("and ")
            descText.append("\(otherAdmins.count - 1) ")
            if otherAdmins.count - 1 == 1 {
                descText.append("other.")
            } else {
                descText.append("others.")
            }
        }
        descText.append("\nTry using the menu item to share with others.")
        return descText
    }
}
