//
//  ChatAddFriendVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import Nuke
import StreamChat
import StreamChatUI
import UIKit

class ChatAddFriendVC: UIViewController {

    @IBOutlet private var viewHeaderView: UIView!
    @IBOutlet private var viewHeaderViewHeightConst: NSLayoutConstraint!
    @IBOutlet private var viewHeaderViewTopConst: NSLayoutConstraint!
    @IBOutlet private var searchFieldStack: UIStackView!
    @IBOutlet private var searchBarContainerView: UIView!
    @IBOutlet private var tableviewContainerView: UIView!
    @IBOutlet private var searchField: UITextField!
    @IBOutlet private var mainStackView: UIStackView!
    @IBOutlet private weak var btnBack: UIButton!
    @IBOutlet private weak var btnNext: UIButton!
    //
    lazy var chatUserList: ChatUserListVC = {
        let obj = self.storyboard?.instantiateViewController(withIdentifier: "ChatUserListVC") as? ChatUserListVC
        return obj!
    }()
    private var curentSortType: Em_ChatUserListFilterTypes = .sortByLastSeen
    //
    private var isFullScreen = false
    //
    var selectedUsers = [ChatUser]()
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.layoutIfNeeded()
        chatUserList.tableViewFrameUpdate()
    }
    private func setup() {
        //
        btnNext.isEnabled = !self.selectedUsers.isEmpty
        //
        self.searchField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
        //
        addChild(chatUserList)
        tableviewContainerView.addSubview(chatUserList.view)
        chatUserList.didMove(toParent: self)
        tableviewContainerView.updateChildViewContraint(childView: chatUserList.view)
        chatUserList.delegate = self
        chatUserList.userSelectionType = .addFriend
        chatUserList.tableViewFrameUpdate()
        chatUserList.curentSortType = .sortByAtoZ
        chatUserList.fetchUserList()
        //
        viewHeaderView.backgroundColor = UIColor.viewBackground
        searchBarContainerView.backgroundColor = UIColor.searchBarBackground
        //
        searchBarContainerView.layer.cornerRadius = 20.0
        viewHeaderView.layer.cornerRadius = 20.0
        //
        
        viewHeaderView.addSwipeGestureRecognizer(for: .up, target: self, action: #selector(self.addPangGesture(_:)))
        viewHeaderView.addSwipeGestureRecognizer(for: .down, target: self, action: #selector(self.addPangGesture(_:)))
    }
    //
    @objc private func textDidChange(_ sender: UITextField) {
        self.chatUserList.searchDataUsing(searchString: sender.text)
    }
    @objc private func addPangGesture(_ sender: UIPanGestureRecognizer) {
        UIView.animate(withDuration: 0.1) {
            if self.isFullScreen {
                self.viewHeaderViewTopConst.priority = .defaultLow
                self.viewHeaderViewHeightConst.priority = .defaultHigh
                self.isFullScreen = false
            } else {
                self.isFullScreen = true
                self.viewHeaderViewTopConst.priority = .defaultHigh
                self.viewHeaderViewHeightConst.priority = .defaultLow
            }
            self.view.layoutIfNeeded()
        }
    }
    //
    // MARK: - Actions
    //
    @IBAction private func btnBackAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction private func invitLinkAction(_ sender: UIButton) {
        //
    }
    // swiftlint:disable redundant_type_annotation
    @IBAction private func btnDoneAction(_ sender: UIButton) {
        
    }
    //
}

// MARK: - ChatUserListDelegate
extension ChatAddFriendVC: ChatUserListDelegate {
    func chatListStateUpdated(state: ChatUserListVC.ChatUserLoadingState) {
        
    }
    func chatUserDidSelect() {
        self.selectedUsers = self.chatUserList.selectedUsers
        btnNext.isEnabled = !self.selectedUsers.isEmpty
    }
}
