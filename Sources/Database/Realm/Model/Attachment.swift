//
//  Attachment.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 27/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class Attachment: Object {
    
    @objc dynamic var title = ""
    @objc dynamic var author: String?
    @objc dynamic var text: String?
    @objc dynamic var type: String?
    @objc dynamic var url: String?
    @objc dynamic var imageURL: String?
    @objc dynamic var file: AttachmentFile?
    @objc dynamic var extraData: Data?
    let actions = List<AttachmentAction>()
    
    var asAttachment: StreamChatCore.Attachment {
        return StreamChatCore.Attachment(type: AttachmentType(rawValue: type),
                                         title: title,
                                         url: url?.url,
                                         imageURL: imageURL?.url,
                                         file: file?.asAttachmentFile,
                                         extraData: ExtraData.AttachmentWrapper.decode(extraData))
    }
    
    required init() {
        super.init()
    }
    
    init(_ attachment: StreamChatCore.Attachment) {
        title = attachment.title
        author = attachment.author
        text = attachment.text
        type = attachment.type.rawValue
        url = attachment.url?.absoluteString
        imageURL = attachment.imageURL?.absoluteString
        extraData = attachment.extraData?.encode()
        actions.append(objectsIn: attachment.actions.map({ AttachmentAction($0) }))
        
        if let attachmentFile = attachment.file {
            file = AttachmentFile(attachmentFile)
        }
    }
}

// MARK: - Attachment Action

final class AttachmentAction: Object {
    @objc dynamic var name = ""
    @objc dynamic var value = ""
    @objc dynamic var style = ""
    @objc dynamic var type = ""
    @objc dynamic var text = ""
    
    var asAction: StreamChatCore.Attachment.Action? {
        guard let style = StreamChatCore.Attachment.ActionStyle(rawValue: style),
            let type = StreamChatCore.Attachment.ActionType(rawValue: type) else {
                return nil
        }
        
        return StreamChatCore.Attachment.Action(name: name, value: value, style: style, type: type, text: text)
    }
    
    required init() {
        super.init()
    }
    
    init(_ action: StreamChatCore.Attachment.Action) {
        name = action.name
        value = action.value
        style = action.style.rawValue
        type = action.type.rawValue
        text = action.text
    }
}

final class AttachmentFile: Object {
    @objc dynamic var type = ""
    @objc dynamic var size: Int64 = 0
    @objc dynamic var mimeType: String?
    
    var asAttachmentFile: StreamChatCore.AttachmentFile? {
        guard let type = StreamChatCore.AttachmentFileType(rawValue: type) else {
            return nil
        }
        
        return StreamChatCore.AttachmentFile(type: type, size: size, mimeType: mimeType)
    }
    
    required init() {
        super.init()
    }
    
    init(_ attachmentFile: StreamChatCore.AttachmentFile) {
        type = attachmentFile.type.rawValue
        size = attachmentFile.size
        mimeType = attachmentFile.mimeType
    }
}
