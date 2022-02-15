//
//  ChatSharedFilesVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import UIKit
import StreamChatUI
import StreamChat

public class ChatSharedFilesVC: UIViewController {
    // MARK: - OUTLETS
    @IBOutlet public weak var lblEmpty: UILabel?
    // MARK: - VARIABLES
    public var attachmentType = AttachmentType.unknown
    // MARK: - VIEW CYCEL
    public override func viewDidLoad() {
        super.viewDidLoad()
        //
        self.view.backgroundColor = .clear
        //
        self.setupUI()
    }
    //
}
// MARK: - UI
extension ChatSharedFilesVC {
    //
    public func setupUI() {
        lblEmpty?.textColor = Appearance.default.colorPalette.subtitleText
        //
        switch self.attachmentType {
        case .image,.video:
            self.lblEmpty?.text = "No media available"
        case .file:
            self.lblEmpty?.text = "No files available"
        case .linkPreview:
            self.lblEmpty?.text = "No link available"
        default:
            self.lblEmpty?.text = "unknown type"
        }
    }
}
