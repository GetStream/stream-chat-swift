//
//  ChatGroupDetailsVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import Foundation
import Nuke
import StreamChat
import StreamChatUI
import UIKit

public class ChatGroupDetailsVC: ChatBaseVC {

    
    
    //
    @IBOutlet private var headerView: ChatChannelHeaderView!
    @IBOutlet private var lblTitle: UILabel!
    @IBOutlet private var lblSubtitle: UILabel!
    //
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var filesContainerView: UIView!
    @IBOutlet private var buttonMedia: UIButton!
    @IBOutlet private var buttonFiles: UIButton!
    @IBOutlet private var buttonLinks: UIButton!
    @IBOutlet private var indicatorViewLeadingContraint: NSLayoutConstraint!
    //
    public var selectedUsers: [ChatChannelMember] = []
    //
    private let scrollViewFiles = UIScrollView()
    private let viewTabIndicator = UIView()
    //
    public var channelController: ChatChannelController?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        //
        setupUI()
        //
        configureFilesView()
    }
    open func setupUI() {
        //
        self.view.backgroundColor = UIColor.black
        //
        let name = self.channelController?.channel?.name ?? ""
        let friendCount = self.channelController?.channel?.memberCount ?? 0
        //let onlineUser = self.channelController?.channel?.lastActiveMembers.count ?? 0
        lblTitle.text = name
        lblSubtitle.text = "\(friendCount) friends"
        
        if let cid = channelController?.cid {
//            headerView.channelController = ChatClient.shared.channelController(for: cid)
            
            let controller = ChatClient.shared.memberListController(query: .init(cid: cid))
            controller.synchronize { [weak self] error in
                guard error == nil, let weakSelf = self else { return }
                DispatchQueue.main.async {
                    weakSelf.selectedUsers =  (controller.members ?? []).filter({ $0.id != nil })
                    for member in controller.members {
                        print(member.name)
                    }
                    weakSelf.tableView.reloadData()
                }
            }
        }
//        let str = self.selectedUsers.count > 1 ? "friends" : "friend"
//        lblSubtitle.text = "\(channelController?.channel?.memberCount ?? 0)"
        //
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView?.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        //
        tableView.dataSource = self
        tableView.bounces = false
        // An old trick to force the table view to hide empty lines
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        tableView.separatorStyle = .none
    }
    //
    @IBAction func backBtnTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func doneTapped(_ sender: UIButton) {
        //
        
    }
    @IBAction func addFriendButtonAction(_ sender: UIButton) {
        //
        guard let controller = ChatAddFriendVC
                .instantiateController(storyboard: .GroupChat)  as? ChatAddFriendVC else {
            return
        }
        //
        controller.bCallbackAddUser = { [weak self] users in
            guard let weakSelf = self else { return }
            let ids = users.map{ $0.id}
            weakSelf.channelController?.addMembers(userIds: Set(ids), completion: { error in
                if error == nil {
                    weakSelf.navigationController?.popViewController(animated: false)
                } else {
                    weakSelf.presentAlert(title: "Error", message: error!.localizedDescription)
                }
            })
        }
        //
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        
        self.present(controller, animated: true, completion: nil)
    }
    @IBAction func mediaButtonAction(_ sender: UIButton) {
        //
        self.scrollToPage(page: .media, animated: false)
    }
    @IBAction func fileButtonAction(_ sender: UIButton) {
        //
        self.scrollToPage(page: .files, animated: false)
    }
    @IBAction func linkButtonAction(_ sender: UIButton) {
        //
        self.scrollToPage(page: .link, animated: false)
    }
}
// MARK: - Collection View
extension ChatGroupDetailsVC {
    //
    private func configureFilesView() {
        scrollViewFiles.delegate = self
        self.filesContainerView.addSubview(scrollViewFiles)
        scrollViewFiles.frame = self.filesContainerView.bounds
        var xValue: CGFloat = 0
        let width = UIScreen.main.bounds.width
        //
        let arr: [ChatSharedFilesVC.FileType] = [.media, .files, .link]
        for index in 0..<arr.count {
            //
            xValue = self.scrollViewFiles.frame.size.width * CGFloat(index)
//            frame.size = self.scrollViewFiles.frame.size
            //
            let subView = ChatSharedFilesVC()
            addChild(subView)
            subView.view.frame = CGRect.init(x: xValue, y: 0, width: width, height: self.filesContainerView.bounds.height)
            self.scrollViewFiles.addSubview(subView.view)
            subView.didMove(toParent: self)
            subView.setFileType(type: arr[index])
        }
        self.scrollViewFiles.isPagingEnabled = true
        self.scrollViewFiles.contentSize = CGSize(width: self.scrollViewFiles.frame.size.width * 3, height: self.scrollViewFiles.frame.size.height)
    }
    //
    public func scrollToPage(page: ChatSharedFilesVC.FileType, animated: Bool) {
        var frame: CGRect = self.scrollViewFiles.frame
        frame.origin.x = frame.size.width * CGFloat(page.rawValue)
        frame.origin.y = 0
        self.scrollViewFiles.scrollRectToVisible(frame, animated: animated)
        self.updateIndicator(page: page, animated: true)
        
    }
    public func updateIndicator(page: ChatSharedFilesVC.FileType, animated: Bool) {
        UIView.animate(withDuration: 0.1) {
            switch page {
            case .media:
                //let center = self.buttonMedia.center
                self.indicatorViewLeadingContraint.constant = self.buttonMedia.frame.origin.x
            case .files:
                self.indicatorViewLeadingContraint.constant = self.buttonFiles.frame.origin.x
            case .link:
                self.indicatorViewLeadingContraint.constant = self.buttonLinks.frame.origin.x
            }
            self.view.layoutIfNeeded()
        }
    }
}
// MARK: - TABLEVIEW
extension ChatGroupDetailsVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedUsers.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reuseID = TableViewCellChatUser.reuseId
        //
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: reuseID,
            for: indexPath) as? TableViewCellChatUser else {
            return UITableViewCell()
        }
        //
        let user: ChatChannelMember = selectedUsers[indexPath.row]
        //
        cell.config(user: user,
                        selectedImage: nil,
                        avatarBG: view.tintColor)
        //
        cell.lblRole.text = ""
        cell.lblRole.isHidden = true
        if user.memberRole == .admin {
            cell.lblRole.text = "Owner"
            cell.lblRole.textColor = ChatColor.STATUS
            cell.lblRole.isHidden = false
        }
        //
        cell.backgroundColor = .clear
        return cell
        //
    }
}

extension ChatGroupDetailsVC: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        if let type = ChatSharedFilesVC.FileType.init(rawValue: Int(pageNumber)) {
            self.updateIndicator(page: type, animated: true)
        }
    }
}
