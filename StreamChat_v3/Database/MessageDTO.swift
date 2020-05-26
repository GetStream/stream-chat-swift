//
//  MessageDTO+CoreDataClass.swift
//  AirChat
//
//  Created by Vojta on 20/05/2020.
//  Copyright © 2020 VojtaStavik.com. All rights reserved.
//
//

import Foundation
import CoreData

@objc(MessageDTO)
public class MessageDTO: NSManagedObject {
    
    static let entityName = "MessageDTO"
    
    @NSManaged fileprivate var id: String
    @NSManaged fileprivate var text: String
    @NSManaged fileprivate var additionalStateRaw: Int16
    @NSManaged /* fileprivate */ var timestamp: Date
    
    @NSManaged fileprivate var user: UserDTO
    @NSManaged fileprivate var channelId: String?
}

//extension Message {
//
//    static func messagesForChannelFetchRequest(channelId: Channel.Id) -> NSFetchRequest<MessageDTO> {
//        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
//        request.predicate = NSPredicate(format: "channelId == %@", channelId)
//        request.sortDescriptors = [.init(key: "timestamp", ascending: true)]
//        return request
//    }
//
//    static func messagesPendingSendFetchRequest() -> NSFetchRequest<MessageDTO> {
//        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
//        request.predicate = NSPredicate(format: "additionalStateRaw == %d", Message.State.pendingSend.rawValue)
//        request.sortDescriptors = [.init(key: "timestamp", ascending: true)]
//        return request
//    }
//
//    func save(to context: NSManagedObjectContext) {
//        _ = dto(in: context)
//    }
//
//    func dto(in context: NSManagedObjectContext) -> MessageDTO {
//        let dto = MessageDTO(context: context)
//        dto.id = id
//        dto.text = text
//        dto.additionalStateRaw = additionalState?.rawValue ?? -1
//        dto.timestamp = timestamp
//        dto.channelId = channelId
//        dto.user = user.save(to: context)
//        return dto
//    }
//
//    init(id: Message.Id, context: NSManagedObjectContext) {
//        let request = NSFetchRequest<MessageDTO>(entityName: MessageDTO.entityName)
//        request.predicate = NSPredicate(format: "id == %@", id)
//        let dto = try! context.fetch(request).first!
//        self.init(from: dto)
//    }
//
//    init(from dto: MessageDTO) {
//        self.init(additionalState: Message.State(rawValue: dto.additionalStateRaw),
//                  id: dto.id,
//                  text: dto.text,
//                  user: User(from: dto.user),
//                  timestamp: dto.timestamp,
//                  channelId: dto.channelId)
//    }
//}
//