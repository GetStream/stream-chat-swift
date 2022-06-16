//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import Nuke
import StreamChat
import StreamChatUI
import UIKit

class CreateGroupViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var selectedUsersStackView: UIStackView! {
        didSet {
            selectedUsersStackView.isLayoutMarginsRelativeArrangement = true
        }
    }

    @IBOutlet var selectedUsersCollectionView: UICollectionView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var noMatchView: UIView!
    @IBOutlet var infoStackView: UIStackView! {
        didSet {
            infoStackView.isLayoutMarginsRelativeArrangement = true
        }
    }

    @IBOutlet var infoLabel: UILabel!
    
    var searchController: ChatUserSearchController!
    
    var users: [ChatUser] {
        searchController.userArray
    }
    
    var selectedUsers = [ChatUser]()
    
    @IBOutlet var searchField: UISearchBar!
    @IBOutlet var mainStackView: UIStackView!
    
    var operation: DispatchWorkItem?
    let throttleTime = 1000
    
    lazy var nextButton: UIBarButtonItem = UIBarButtonItem(
        image: UIImage(named: "Icon_arrow_right"),
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
        
        // Remove the back button title
        let backButton = UIBarButtonItem()
        backButton.title = ""
        backButton.tintColor = .label
        navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        
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
        infoLabel.text = "On the platform"
    }
    
    @objc func searchFieldDidChange(_ sender: UISearchTextField) {
        noMatchView.isHidden = true
        loadingIndicator.startAnimating()
        
        if let text = sender.text, !text.isEmpty {
            infoLabel.text = "Matches for \"\(text)\""
        } else {
            infoLabel.text = "On the platform"
        }
        
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
        nameGroupController.client = searchController.client
        
        navigationController?.pushViewController(nameGroupController, animated: true)
    }
    
    func showSelectedUsers(_ show: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.selectedUsersCollectionView.isHidden = !show
            self.navigationItem.rightBarButtonItem = show ? self.nextButton : nil
        }
    }
}

// MARK: ChatUserSearchControllerDelegate functions

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

// MARK: UITableViewDataSource functions

extension CreateGroupViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserCell", for: indexPath) as? SearchUserCell else {
            return UITableViewCell()
        }
        
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
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) as? SearchUserCell else {
            return
        }
        guard cell.accessoryImageView.image == nil else {
            // The cell isn't selected
            // De-select user by tapping functionality was removed due to designer feedback
            return
        }
        
        // Select user
        cell.accessoryImageView.image = UIImage(systemName: "checkmark.circle.fill")
        if let user = cell.user {
            selectedUsers.append(user)
        }

        showSelectedUsers(!selectedUsers.isEmpty)
        selectedUsersCollectionView.reloadData()
    }
}

// MARK: UICollectionViewDataSource functions

extension CreateGroupViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupUserCell", for: indexPath) as? GroupUserCell else {
            return UICollectionViewCell()
        }
        
        let user = selectedUsers[indexPath.row]
        
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: cell.avatarView)
        }
        cell.avatarView.backgroundColor = .clear
        cell.nameLabel.text = user.name
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let id = selectedUsers[indexPath.row].id
        
        selectedUsers.remove(at: indexPath.row)
        collectionView.deleteItems(at: [indexPath])
        showSelectedUsers(!selectedUsers.isEmpty)
        
        if let cell = tableView.visibleCells.first(where: { ($0 as? SearchUserCell)?.user?.id == id }) as? SearchUserCell {
            cell.accessoryImageView.image = nil
        }
    }
}
