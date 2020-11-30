//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import Nuke
import StreamChat
import UIKit

class GroupUserCell: UICollectionViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var avatarView: AvatarView!
}

class SearchUserCell: UITableViewCell {
    @IBOutlet var mainStackView: UIStackView!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var accessoryImageView: UIImageView!
    
    var user: ChatUser?
}

class CreateGroupViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var selectedUsersCollectionView: UICollectionView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var noMatchView: UIView!
    
    var searchController: ChatUserSearchController!
    
    var users: [ChatUser] {
        searchController.users
    }
    
    var selectedUsers = [ChatUser]()
    
    @IBOutlet var searchField: UISearchBar!
    @IBOutlet var mainStackView: UIStackView! {
        didSet {
            mainStackView.isLayoutMarginsRelativeArrangement = true
        }
    }
    
    var operation: DispatchWorkItem?
    let throttleTime = 1000
    
    lazy var nextButton: UIBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "arrow.right"),
        style: .done,
        target: self,
        action: #selector(nextTapped)
    )
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.bounces = false
        
        // An old trick to force the table view to hide empty lines
        tableView.tableFooterView = UIView()
        
        searchController.delegate = self
        
        selectedUsersCollectionView.isHidden = true
        
        selectedUsersCollectionView.dataSource = self
        selectedUsersCollectionView.delegate = self
        
        searchField.searchTextField.addTarget(self, action: #selector(searchFieldDidChange(_:)), for: .editingChanged)
        
        loadingIndicator.startAnimating()
        searchController.search(term: nil) // Empty initial search to get all users
        
        view.bringSubviewToFront(searchField)
    }
    
    @objc func searchFieldDidChange(_ sender: UISearchTextField) {
        noMatchView.isHidden = true
        loadingIndicator.startAnimating()
        
        operation?.cancel()
        operation = DispatchWorkItem { [weak self] in
            self?.searchController.search(term: sender.text) { _ in
                // TODO: handle error
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(throttleTime), execute: operation!)
    }
    
    @objc func nextTapped() {
        let nameGroupController = NameGroupViewController(nibName: nil, bundle: nil)
        nameGroupController.selectedUsers = selectedUsers
        
        navigationController?.pushViewController(nameGroupController, animated: true)
    }
    
    func showSelectedUsers(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.selectedUsersCollectionView.isHidden = !show
            self.navigationItem.rightBarButtonItem = show ? self.nextButton : nil
        }
    }
}

extension CreateGroupViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SearchUserCell
        let user = users[indexPath.row]
        
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: cell.avatarView)
        }
        cell.avatarView.backgroundColor = view.tintColor
        cell.nameLabel.text = user.name
        
        if let lastActive = user.lastActiveAt {
            cell.descriptionLabel.text = "Last seen: " + formatter.string(from: lastActive)
        } else {
            cell.descriptionLabel.text = "Never seen"
        }
        
        if selectedUsers.contains(where: { $0.id == user.id }) {
            cell.accessoryImageView.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            cell.accessoryImageView.image = nil
        }
        
        cell.user = user
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! SearchUserCell
        
        if cell.accessoryImageView.image == nil {
            // Select user
            cell.accessoryImageView.image = UIImage(systemName: "checkmark.circle.fill")
            if let user = cell.user {
                selectedUsers.append(user)
            }
        } else {
            // Deselect user
            cell.accessoryImageView.image = nil
            if let user = cell.user {
                selectedUsers.removeAll(where: { $0.id == user.id })
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
        showSelectedUsers(!selectedUsers.isEmpty)
        selectedUsersCollectionView.reloadData()
    }
}

extension CreateGroupViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GroupUserCell
        let user = selectedUsers[indexPath.row]
        
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: cell.avatarView)
        }
        cell.avatarView.backgroundColor = .clear
        cell.nameLabel.text = user.name
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedUsers.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
    }
}

extension CreateGroupViewController: ChatUserSearchControllerDelegate {
    func controller(_ controller: ChatUserSearchController, didChangeUsers changes: [ListChange<ChatUser>]) {
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
    
    func controller(_ controller: DataController, didChangeState state: DataController.State) {
        if case .remoteDataFetched = state {
            print("\(users.count) users found")
            loadingIndicator.stopAnimating()
            noMatchView.isHidden = !users.isEmpty
        }
    }
}
