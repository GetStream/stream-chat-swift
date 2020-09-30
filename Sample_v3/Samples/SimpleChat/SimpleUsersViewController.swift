//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import UIKit

class SimpleUsersViewController: UITableViewController, ChatUserListControllerDelegate {
    var userListController: ChatUserListController! {
        didSet {
            userListController.delegate = self
            userListController.synchronize()
        }
    }
    
    func controller(
        _ controller: ChatUserListController,
        didChangeUsers changes: [ListChange<ChatUser>]
    ) {
        tableView.beginUpdates()
        
        for change in changes {
            switch change {
            case let .insert(_, index: index):
                tableView.insertRows(at: [index], with: .automatic)
            case let .move(_, fromIndex: fromIndex, toIndex: toIndex):
                tableView.moveRow(at: fromIndex, to: toIndex)
            case let .update(_, index: index):
                tableView.reloadRows(at: [index], with: .automatic)
            case let .remove(_, index: index):
                tableView.deleteRows(at: [index], with: .automatic)
            }
        }
        
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        userListController.users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = userListController.users[indexPath.row]
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        if (!(cell != nil)) {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        
        cell!.textLabel?.text = user.name
        return cell!
    }
}
