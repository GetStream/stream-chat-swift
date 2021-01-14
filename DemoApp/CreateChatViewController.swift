//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import Nuke
import StreamChat
import StreamChatUI
import UIKit

class CreateChatViewController: UIViewController {
    enum State {
        case searching, loading, noUsers, selected, error
    }
    
    // Composer subclass intended to be only used in this VC
    class DemoComposerVC: MessageComposerViewController<DefaultExtraData> {
        override func createNewMessage(text: String) {
            guard let navController = parent?.parent as? UINavigationController,
                let controller = controller else { return }
            // Create the Channel on backend
            controller.synchronize { error in
                // TODO: handle error
                if let error = error { print("###", error) }
                
                // Send the message
                super.createNewMessage(text: text)
                
                // Present the new chat and controller
                let vc = ChatChannelVC<ExtraData>()
                vc.channelController = controller
                vc.userSuggestionSearchController = controller.client.userSearchController()
                
                navController.setViewControllers([navController.viewControllers.first!, vc], animated: true)
            }
        }
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var noMatchView: UIView!
    @IBOutlet var searchField: UISearchTextField!
    @IBOutlet var addPersonButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var mainStackView: UIStackView!
    @IBOutlet var createGroupStack: UIStackView! {
        didSet {
            createGroupStack.isLayoutMarginsRelativeArrangement = true
        }
    }

    @IBOutlet var infoLabelStackView: UIStackView! {
        didSet {
            infoLabelStackView.isLayoutMarginsRelativeArrangement = true
        }
    }
    
    @IBOutlet var alertImage: UIImageView!
    @IBOutlet var alertText: UILabel!
    
    var composerView: DemoComposerVC!
    
    var searchController: ChatUserSearchController!
    
    var users: [ChatUser] {
        searchController.users
    }
    
    var selectedUserIds: Set<String> {
        Set(searchField.tokens.compactMap { ($0.representedObject as? ChatUser)?.id })
    }
    
    var operation: DispatchWorkItem?
    let throttleTime = 1000
    
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
        
        searchField.allowsDeletingTokens = true
        
        searchController.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openCreateGroupChat))
        createGroupStack.addGestureRecognizer(tapGestureRecognizer)
        
        // ComposerView
        
        composerView = DemoComposerVC()
        composerView.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(composerView) // , targetView: view)
        view.addSubview(composerView.view)
        composerView.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
            .isActive = true
        composerView.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            .isActive = true
        view.bottomAnchor.constraint(equalTo: composerView.view.bottomAnchor).isActive = true
        
        // Empty initial search to get all users
        searchController.search(term: nil) { error in
            if error != nil {
                self.update(for: .error)
            }
        }
        infoLabel.text = "On the platform"
        update(for: .loading)
    }
    
    func update(for state: State) {
        switch state {
        case .error:
            // TODO: error handling
            break
        case .searching:
            searchField.becomeFirstResponder()
            noMatchView.isHidden = true
            activityIndicator.stopAnimating()
            createGroupStack.isHidden = searchField.hasText || !selectedUserIds.isEmpty
            tableView.alpha = 1
            addPersonButton.setImage(UIImage(systemName: "person"), for: .normal)
            infoLabelStackView.isHidden = false
        case .noUsers:
            noMatchView.isHidden = false
            activityIndicator.stopAnimating()
            createGroupStack.isHidden = true
            tableView.alpha = 0
            addPersonButton.setImage(UIImage(systemName: "person"), for: .normal)
            infoLabelStackView.isHidden = false
            alertImage.image = UIImage(systemName: "magnifyingglass")
            alertText.text = "No user matches these keywords..."
        case .loading:
            noMatchView.isHidden = true
            activityIndicator.startAnimating()
            createGroupStack.isHidden = true
            tableView.alpha = 0
            addPersonButton.setImage(UIImage(systemName: "person"), for: .normal)
            infoLabelStackView.isHidden = false
        case .selected:
            noMatchView.isHidden = false
            activityIndicator.stopAnimating()
            createGroupStack.isHidden = true
            tableView.alpha = 0
            addPersonButton.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
            infoLabelStackView.isHidden = true
            alertImage.image = nil
            alertText.text = "No chats here yet..."
        }
    }
    
    @IBAction func searchFieldDidChange(_ sender: UISearchTextField) {
        update(for: .loading)
        
        if let text = sender.text, !text.isEmpty {
            infoLabel.text = "Matches for \"\(text)\""
        } else {
            infoLabel.text = "On the platform"
        }
        
        operation?.cancel()
        operation = DispatchWorkItem { [weak self] in
            self?.searchController.search(term: sender.text) { error in
                if error != nil {
                    self?.update(for: .error)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(throttleTime), execute: operation!)
    }
    
    @IBAction func addPersonTapped(_ sender: Any) {
        update(for: .searching)
    }
    
    @objc func openCreateGroupChat() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        let createGroupController = storyboard.instantiateViewController(withIdentifier: "CreateGroupViewController")
            as! CreateGroupViewController
        createGroupController.searchController = searchController
        
        navigationController?.pushViewController(createGroupController, animated: true)
    }
}

extension CreateChatViewController: ChatUserSearchControllerDelegate {
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
            update(for: users.isEmpty ? .noUsers : .searching)
        }
    }
}

extension CreateChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserCredentialsCell
        let user = users[indexPath.row]
        
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: cell.avatarView)
        }
        cell.avatarView.backgroundColor = view.tintColor
        cell.nameLabel.text = user.name ?? user.id
        
        if let lastActive = user.lastActiveAt {
            cell.descriptionLabel.text = "Last seen: " + formatter.string(from: lastActive)
        } else {
            cell.descriptionLabel.text = "Never seen"
        }
        
        if selectedUserIds.contains(user.id) {
            cell.accessoryImageView.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            cell.accessoryImageView.image = nil
        }
        
        cell.user = user
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! UserCredentialsCell
        
        if cell.accessoryImageView.image == nil {
            // Select user
            cell.accessoryImageView.image = UIImage(systemName: "checkmark.circle.fill")
            let token = UISearchToken(
                icon: cell.avatarView.image?.resized(to: .init(width: 20, height: 20)),
                text: cell.user?.name ?? cell.user?.id ?? "NoName"
            )
            token.representedObject = cell.user
            searchField.replaceTextualPortion(of: searchField.textualRange, with: token, at: searchField.tokens.count)
            
            update(for: .selected)
        } else {
            // Deselect user
            cell.accessoryImageView.image = nil
            if let tokenIndex = searchField.tokens.firstIndex(where: { ($0.representedObject as? ChatUser)?.id == cell.user?.id }) {
                searchField.removeToken(at: tokenIndex)
            }
            
            update(for: .searching)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        do {
            composerView.controller = try searchController.client
                .channelController(
                    createDirectMessageChannelWith: selectedUserIds,
                    name: nil,
                    imageURL: nil,
                    extraData: .defaultValue
                )
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.bounds.height
        guard bottomEdge >= scrollView.contentSize.height else { return }
        searchController.loadNextUsers()
    }
}

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio) :
            CGSize(
                width: size.width * widthRatio,
                height: size.height * widthRatio
            )
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
