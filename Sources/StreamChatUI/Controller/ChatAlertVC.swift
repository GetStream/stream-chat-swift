//
//  ChatAlertVC.swift
//  Pods
//
//  Created by Jitendra Sharma on 14/02/22.
//

import UIKit

public class ChatAlertVC: UIViewController {
    
    public struct DataModel {
        let title: String
        let message: String
        let actionButtonTitle: String
    }
    //
    public enum AlertType {
        case leaveChatRoom
        case deleteGroup
        //
        var data: DataModel {
            switch self {
            case .leaveChatRoom:
                return DataModel(title: "Leave Chatroom", message: "Are you sure you want to leave this chatroom? If you leave, your chat history will be permanently deleted.", actionButtonTitle: "Leave Chatroom")
            case .deleteGroup:
                return DataModel(title: "Delete Group", message: "Are you sure you want to delete and leave the chatroom? This action cannot be undone and all chat history will be permanently deleted.", actionButtonTitle: "Delete Chatroom")
            }
        }
    }
    //MARK: - OUTLETS
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    //MARK: - VARIABLES
    var alertType: ChatAlertVC.AlertType!
    var bCallbackActionHandler:(() -> Void)?
    
    //MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    //MARK: - METHODS
    private func setupUI() {
        self.titleLabel.text = self.alertType.data.title
        self.messageLabel.text = self.alertType.data.message
        let attributedString = NSMutableAttributedString(string: self.alertType.data.message)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        messageLabel.attributedText = attributedString
        self.actionButton.setTitle(self.alertType.data.actionButtonTitle, for: .normal)
        self.actionButton.layer.cornerRadius = actionButton.bounds.height/2
        self.cancelButton.layer.cornerRadius = actionButton.bounds.height/2
    }
    
    @IBAction func actionButton(_ sender: UIButton) {
        self.bCallbackActionHandler?()
        self.cancelButtonAction(sender)
    }
    
    @IBAction func cancelButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: PanModalPresentable
extension ChatAlertVC: PanModalPresentable {
    public var panScrollable: UIScrollView? {
        return nil
    }

    public var shortFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(382)
    }

    public var longFormHeight: PanModalHeight {
        return .contentHeightIgnoringSafeArea(382)
    }

    public var anchorModalToLongForm: Bool {
        return true
    }

    public var showDragIndicator: Bool {
        return false
    }

    public var allowsExtendedPanScrolling: Bool {
        return false
    }

    public var allowsDragToDismiss: Bool {
        return true
    }

    public var cornerRadius: CGFloat {
        return 34
    }

    public var isHapticFeedbackEnabled: Bool {
        return true
    }
}
