//
//  ChatGroupDetailsVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import Foundation
import Nuke
import StreamChat
import UIKit

public class ChatGroupDetailsVC: UIViewController {

    var client: ChatClient?
    @IBOutlet private weak var btnNext: UIButton!
    //
    @IBOutlet private var lblGroupName: UILabel!
    @IBOutlet private var lblSubtitle: UILabel!
    //
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var filesContainerView: UIView!
    @IBOutlet private var buttonMedia: UIButton!
    @IBOutlet private var buttonFiles: UIButton!
    @IBOutlet private var buttonLinks: UIButton!
    @IBOutlet private var indicatorViewLeadingContraint: NSLayoutConstraint!
    //
    var selectedUsers: [ChatUser]!
    //
    private let scrollViewFiles = UIScrollView()
    private let viewTabIndicator = UIView()
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        setupUI()
        //
        configureFilesView()
    }
    func setupUI() {
        //
        let str = self.selectedUsers.count > 1 ? "friends" : "friend"
        lblSubtitle.text = "\(self.selectedUsers.count) \(str)"
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
        guard let nameGroupController = ChatAddFriendVC
                .instantiate(appStoryboard: .chat)  as? ChatAddFriendVC else {
            return
        }
        nameGroupController.modalPresentationStyle = .overCurrentContext
        nameGroupController.modalTransitionStyle = .crossDissolve
        self.present(nameGroupController, animated: true, completion: nil)
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
    func scrollToPage(page: ChatSharedFilesVC.FileType, animated: Bool) {
        var frame: CGRect = self.scrollViewFiles.frame
        frame.origin.x = frame.size.width * CGFloat(page.rawValue)
        frame.origin.y = 0
        self.scrollViewFiles.scrollRectToVisible(frame, animated: animated)
        self.updateIndicator(page: page, animated: true)
        
    }
    func updateIndicator(page: ChatSharedFilesVC.FileType, animated: Bool) {
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reuseID = TableViewCellChatUser.reuseId
        //
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: reuseID,
            for: indexPath) as? TableViewCellChatUser else {
            return UITableViewCell()
        }
        //
        let user: ChatUser = selectedUsers[indexPath.row]
        //
        cell.config(user: user,
                        selectedImage: nil,
                        avatarBG: view.tintColor)
        cell.backgroundColor = .clear
        return cell
        //
    }
}

extension ChatGroupDetailsVC: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {

        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        if let type = ChatSharedFilesVC.FileType.init(rawValue: Int(pageNumber)) {
            self.updateIndicator(page: type, animated: true)
        }
    }
}
