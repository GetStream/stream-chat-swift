//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension UITableViewController {
    func channelCellWithName(_ channelName: String?, subtitle: String, unreadCount: Int) -> UITableViewCell {
        let cell: UITableViewCell
        if let _cell = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            cell = _cell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        }
        
        cell.textLabel?.text = channelName
        cell.detailTextLabel?.text = subtitle
        
        if unreadCount > 0 {
            // set channel name font to bold
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: cell.textLabel?.font.pointSize ?? UIFont.labelFontSize)
            
            // set accessory view to number of unread messages
            let unreadLabel = UILabel()
            unreadLabel.text = "\(unreadCount)"
            cell.accessoryView = unreadLabel
        }
        
        return cell
    }
    
    func messageCellWithAuthor(_ author: String?, messageText: String) -> UITableViewCell {
        let cell: UITableViewCell!
        if let _cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") {
            cell = _cell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "MessageCell")
        }
        
        cell.textLabel?.numberOfLines = 0
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        if let author = author {
            let font = cell.textLabel?.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
            let boldFont = UIFont(
                descriptor: font.fontDescriptor.withSymbolicTraits([.traitBold]) ?? font.fontDescriptor,
                size: font.pointSize
            )
            
            let attributedString = NSMutableAttributedString()
            attributedString.append(
                .init(
                    string: "\(author) ",
                    attributes: [
                        NSAttributedString.Key.font: boldFont,
                        NSAttributedString.Key.foregroundColor: UIColor.forUsername(author)
                    ]
                )
            )
            attributedString.append(.init(string: messageText))
            
            cell.textLabel?.attributedText = attributedString
        } else {
            cell?.textLabel?.text = messageText
        }
        
        return cell
    }
    
    func memberCell(_ member: ChatChannelMember, isCurrentUser: Bool) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withIdentifier: "MemberCell") ?? .init(style: .default, reuseIdentifier: "MemberCell")
        cell.textLabel?.text = createMemberNameAndStatusInfoString(for: member, isCurrentUser: isCurrentUser)
        cell.textLabel?.textColor = member.name.flatMap(UIColor.forUsername) ?? .black
        cell.textLabel?.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .boldSystemFont(ofSize: UIFont.systemFontSize))
        cell.textLabel?.adjustsFontSizeToFitWidth = true

        cell.detailTextLabel?.text = createMemberOnlineStatusInfoString(for: member)
        cell.detailTextLabel?.textColor = member.isOnline ? .blue : .lightGray
        cell.detailTextLabel?.font = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .systemFont(ofSize: UIFont.smallSystemFontSize))
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true

        let banStatusLabel = UILabel(frame: .init(x: 0, y: 0, width: 100, height: 40))
        banStatusLabel.text = createMemberRoleString(for: member)
        banStatusLabel.textAlignment = .right
        banStatusLabel.textColor = .darkGray
        banStatusLabel.font = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .boldSystemFont(ofSize: UIFont.smallSystemFontSize))
        banStatusLabel.adjustsFontForContentSizeCategory = true
        cell.accessoryView = banStatusLabel
        
        return cell
    }
}
