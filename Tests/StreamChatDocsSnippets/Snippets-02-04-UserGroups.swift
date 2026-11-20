//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/user-groups/

import StreamChat

struct Snippets_02_04_UserGroups {
    var chatClient: ChatClient!

    func creatingAUserGroup() {
        let controller = chatClient.userGroupListController()
        controller.createUserGroup(
            name: "Design Team",
            description: "Product design team members",
            memberIds: ["alice", "bob", "charlie"]
        ) { result in
            switch result {
            case .success(let userGroup):
                print("Created group: \(userGroup.name)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    func retrievingAUserGroup() {
        let controller = chatClient.userGroupController(userGroupId: "design-team")
        controller.synchronize { error in
            if let error {
                print("Error: \(error)")
            } else if let userGroup = controller.userGroup {
                print("Group: \(userGroup.name)")
            }
        }
    }

    func listingUserGroups() {
        let query = UserGroupListQuery(limit: 20)
        let controller = chatClient.userGroupListController(query: query)
        controller.synchronize { error in
            if let error {
                print("Error: \(error)")
            } else {
                print("Groups: \(controller.userGroups)")
            }
        }

        // Load more (pagination)
        controller.loadMoreUserGroups { error in
            print("Loaded more groups: \(controller.userGroups.count)")
        }
    }

    func searchingUserGroups() {
        let controller = chatClient.userGroupListController()
        controller.searchUserGroups(text: "design") { result in
            switch result {
            case .success(let groups):
                print("Found \(groups.count) groups")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    func updatingAUserGroup() {
        let controller = chatClient.userGroupController(userGroupId: "design-team")
        controller.update(
            name: "Design & Product Team",
            description: "Product and design team members"
        ) { result in
            switch result {
            case .success(let userGroup):
                print("Updated group: \(userGroup.name)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }

    func deletingAUserGroup() {
        let controller = chatClient.userGroupListController()
        controller.deleteUserGroup(id: "design-team") { error in
            if let error {
                print("Error: \(error)")
            }
        }
    }

    func addingMembers() {
        let controller = chatClient.userGroupController(userGroupId: "design-team")

        // Add members as regular members
        controller.addMembers(["dave", "eve", "frank"]) { result in
            // handle result
        }

        // Add members as group admins
        controller.addMembers(["grace"], asAdmin: true) { result in
            // handle result
        }

        // Promote an existing member to admin
        controller.addMembers(["dave"], asAdmin: true) { result in
            // handle result
        }

        // Demote an admin back to regular member
        controller.addMembers(["dave"], asAdmin: false) { result in
            // handle result
        }
    }

    func removingMembers() {
        let controller = chatClient.userGroupController(userGroupId: "design-team")
        controller.removeMembers(["dave", "eve"]) { result in
            switch result {
            case .success(let userGroup):
                print("Remaining members: \(userGroup.members.count)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
