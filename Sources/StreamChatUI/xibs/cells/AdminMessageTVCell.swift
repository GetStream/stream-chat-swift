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
    case simpleGroupChat
    case privateChat
    case none
}

class AdminMessageTVCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var messageViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Variables
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()

    // MARK: - View life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    // MARK: - Functions
    func configCell(messageCount: Int) {
        if let createdAt = content?.createdAt {
            lblTime.text = dateFormatter.string(from: createdAt)
        } else {
            lblTime.text = nil
        }
        switch content?.extraData.adminMessageType {
        case .daoAddInitialSigners:
            lblDesc.text = getInitialAddSignerDesc()
        case .simpleGroupChat:
            lblDesc.text = getGroupChatAdminMessage()
        default:
            lblDesc.text = ""
        }
        messageViewBottomConstraint.constant = messageCount == 1 ? 0 : 16
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
            var otherAdminsWithoutCreator = otherAdmins.filter { ($0["signerUserId"] as? String ?? "") != content?.author.id }
            descText.append("\(otherAdminsWithoutCreator.first?["signerName"] as? String ?? "") ")
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
    private func getGroupChatAdminMessage() -> String {
        if let members = content?.extraData.adminMessageMembers?.filter { $0.key != ChatClient.shared.currentUserId }.sorted(by: { $0.key > $1.key }) {
            if (content?.isSentByCurrentUser ?? false) {
                let otherUserName = fetchRawData(raw: members.first?.value ?? .string("")) as? String ?? ""
                var joiningText = "You created this group with \(otherUserName)"
                var allMember = content?.extraData.adminMessageMembers ?? [:]
                if allMember.count > 2 {
                    if (allMember.count - 2) >= 2 {
                        joiningText.append(" and \(allMember.count - 2) others.")
                    } else {
                        joiningText.append(" and \(allMember.count - 2) other.")
                    }
                }
                joiningText.append("\nTry using the menu item to share with others.")
                return joiningText
            } else {
                let authorName = (content?.author.name ?? "").capitalizingFirstLetter()
                var joiningText = "\(authorName) created this group with you"
                var allMember = content?.extraData.adminMessageMembers ?? [:]

                if allMember.count > 2 {
                    if (allMember.count - 2) >= 2 {
                        joiningText.append(" and \(allMember.count - 2) others.")
                    } else {
                        joiningText.append(" and \(allMember.count - 2) other.")
                    }
                }
                joiningText.append("\nTry using the menu item to share with others.")
                return joiningText
            }
        } else {
            return content?.extraData.adminMessage ?? "Group Created\nTry using the menu item to share with others"
        }
    }

}
