//
//  ChatClient.swift
//  StreamChat_v3
//
//  Created by Vojta on 26/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import CoreData

public final class ChatClient {

    init(currentUser: User) {
        
    }
    
    
    
    private let persistentContainer: NSPersistentContainer
    
    private func setupPersistentCointaier(userId: String? = nil) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "StreamChatModel")
        
        let description = NSPersistentStoreDescription()
        if let userId = userId {
            
        } else {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
        return container

    }
    
    
}
