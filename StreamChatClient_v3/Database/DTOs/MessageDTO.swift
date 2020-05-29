//
// MessageDTO.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(MessageDTO)
public class MessageDTO: NSManagedObject {
  static let entityName = "MessageDTO"

  @NSManaged fileprivate var id: String
  @NSManaged fileprivate var text: String
  @NSManaged fileprivate var additionalStateRaw: Int16
  @NSManaged fileprivate var timestamp: Date

  @NSManaged fileprivate var user: UserDTO
  @NSManaged fileprivate var channelId: String?
}
