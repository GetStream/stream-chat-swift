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

public class ChatAddFriendVC: ChatBaseVC {
    
    public enum SelectionType {
        case addFriend,inviteUser
        var title: String {
            switch self {
            case .addFriend: return "Add Friends"
            case .inviteUser: return "Invite Friends"
            }
        }
    }
    // MARK: - OUTLETS
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var viewHeaderTitleView: UIView!
    @IBOutlet private var viewHeaderView: UIView!
    @IBOutlet private var viewHeaderViewHeightConst: NSLayoutConstraint!
    @IBOutlet private var viewHeaderViewTopConst: NSLayoutConstraint!
    @IBOutlet private var searchFieldStack: UIStackView!
    @IBOutlet private var searchBarContainerView: UIView!
    @IBOutlet private var tableviewContainerView: UIView!
    @IBOutlet private var searchField: UITextField!
    @IBOutlet private var mainStackView: UIStackView!
    // MARK: - VARIABLES
    public var selectionType = ChatAddFriendVC.SelectionType.addFriend
    public lazy var chatUserList: ChatUserListVC = {
        let obj = ChatUserListVC.instantiateController(storyboard: .GroupChat) as? ChatUserListVC
        return obj!
    }()
    private var curentSortType: Em_ChatUserListFilterTypes = .sortByLastSeen
    private var isFullScreen = false
    public var selectedUsers = [ChatUser]()
    public var bCallbackAddUser:(([ChatUser]) -> Void)?
    var isShortFormEnabled = true
    
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.layoutIfNeeded()
        chatUserList.tableViewFrameUpdate()
    }
   
    // MARK: - METHODS
    public func setup() {
        //
        self.view.backgroundColor = .clear
        self.titleLabel.text = selectionType.title
        btnBack?.setImage(Appearance.Images.closeCircle, for: .normal)
        btnNext?.isEnabled = !self.selectedUsers.isEmpty
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
        viewHeaderView.backgroundColor = Appearance.default.colorPalette.viewBackgroundLightBlack
        searchBarContainerView.backgroundColor = Appearance.default.colorPalette.searchBarBackground
        searchBarContainerView.layer.cornerRadius = 20.0
        viewHeaderView.layer.cornerRadius = 20.0
    }
    //
    @objc private func textDidChange(_ sender: UITextField) {
        self.chatUserList.searchDataUsing(searchString: sender.text)
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
        if self.selectedUsers.count > 0 {
            self.bCallbackAddUser?(self.selectedUsers)
            self.btnBackAction(sender)
        }
    }
}
// MARK: - ChatUserListDelegate
extension ChatAddFriendVC: ChatUserListDelegate {
    public func chatListStateUpdated(state: ChatUserListVC.ChatUserLoadingState) {
        
    }
    public func chatUserDidSelect() {
        self.selectedUsers = self.chatUserList.selectedUsers
        self.btnNext?.isEnabled = !self.selectedUsers.isEmpty
    }
}
// MARK: - Pan Modal Presentable
extension ChatAddFriendVC: PanModalPresentable {

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
//    public var panScrollable: UIScrollView? {
//        return self.chatUserList.view
//    }
    public var panScrollable: UIScrollView? {
        return nil
    }
//    public var longFormHeight: PanModalHeight {
//        return .maxHeightWithTopInset(0)
//    }
    public var shortFormHeight: PanModalHeight {
        return isShortFormEnabled ? .contentHeight(UIScreen.main.bounds.height/2) : longFormHeight
    }
    public var anchorModalToLongForm: Bool {
        return false
    }
    public var showDragIndicator: Bool {
        return false
    }
    public var allowsExtendedPanScrolling: Bool {
        return true
    }
    public var allowsDragToDismiss: Bool {
        return true
    }
    public func willTransition(to state: PanModalPresentationController.PresentationState) {
        guard isShortFormEnabled, case .longForm = state
            else { return }

        isShortFormEnabled = false
        panModalSetNeedsLayoutUpdate()
    }
}
