//
//  AttachmentRealmObject.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 27/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift
import StreamChatCore

public final class AttachmentRealmObject: Object {
    
    @objc dynamic var title = ""
    @objc dynamic var author: String?
    @objc dynamic var text: String?
    @objc dynamic var type: String?
    @objc dynamic var url: String?
    @objc dynamic var imageURL: String?
    @objc dynamic var file: AttachmentFileRealmObject?
    @objc dynamic var extraData: Data?
    let actions = List<AttachmentActionRealmObject>()
    
    var asAttachment: Attachment {
        return Attachment(type: AttachmentType(rawValue: type),
                          title: title,
                          url: url?.url,
                          imageURL: imageURL?.url,
                          file: file?.asAttachmentFile,
                          extraData: ExtraData.AttachmentWrapper.decode(extraData))
    }
    
    required init() {
        super.init()
    }
    
    init(_ attachment: Attachment) {
        title = attachment.title
        author = attachment.author
        text = attachment.text
        type = attachment.type.rawValue
        url = attachment.url?.absoluteString
        imageURL = attachment.imageURL?.absoluteString
        extraData = attachment.extraData?.encode()
        actions.append(objectsIn: attachment.actions.map({ AttachmentActionRealmObject($0) }))
        
        if let attachmentFile = attachment.file {
            file = AttachmentFileRealmObject(attachmentFile)
        }
    }
}

// MARK: - Attachment Action

final class AttachmentActionRealmObject: Object {
    @objc dynamic var name = ""
    @objc dynamic var value = ""
    @objc dynamic var style = ""
    @objc dynamic var type = ""
    @objc dynamic var text = ""
    
    var asAction: Attachment.Action? {
        guard let style = Attachment.ActionStyle(rawValue: style),
            let type = Attachment.ActionType(rawValue: type) else {
                return nil
        }
        
        return Attachment.Action(name: name, value: value, style: style, type: type, text: text)
    }
    
    required init() {
        super.init()
    }
    
    init(_ action: Attachment.Action) {
        name = action.name
        value = action.value
        style = action.style.rawValue
        type = action.type.rawValue
        text = action.text
    }
}

final class AttachmentFileRealmObject: Object {
    @objc dynamic var type = ""
    @objc dynamic var size: Int64 = 0
    @objc dynamic var mimeType: String?
    
    var asAttachmentFile: AttachmentFile? {
        guard let type = AttachmentFileType(rawValue: type) else {
            return nil
        }
        
        return AttachmentFile(type: type, size: size, mimeType: mimeType)
    }
    
    required init() {
        super.init()
    }
    
    init(_ attachmentFile: AttachmentFile) {
        type = attachmentFile.type.rawValue
        size = attachmentFile.size
        mimeType = attachmentFile.mimeType
    }
}
