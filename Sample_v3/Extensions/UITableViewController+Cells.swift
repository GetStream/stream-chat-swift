//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

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
}
