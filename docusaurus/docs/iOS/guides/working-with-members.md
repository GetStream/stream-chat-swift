---
title: Working with Members
---

Users that are in a particular channel are members of this channel. Membership allows handling such things as roles, invitations and bans.
One of the use cases for members is members list for a channel:
<img src={require("../assets/members-list.png").default} width="40%" />

## ChatChannelMember object
Members are represented by `ChatChannelMember` model.

## ChannelMember vs User
`ChatChannelMember` is a subclass of `ChatUser` and apart properties typical for users, it also contains such info as member's role (owner, admin, moderator or member), invitation and ban details.
The difference between these two is that `ChatUser` models represent all the users present on a Stream Chat server, whereas `ChatChannelMember` is user's representation in particular channel. That means that a single user is represented by different `ChatChannelMember` in different channels.

## Getting all members for a channel

`ChatChannelMemberListController` is an entity that provides access to members.
To get all the members for a channel with `general` id:
```swift
let memberListController = chatClient.memberListController( 
    query: .init(cid: .init(type: .messaging, id: "general"), filter: .none) 
)

memberListController.synchronize { error in 
    // handle error / access members 
    print(error ?? memberListController.members) 
}
```

## Filtering members

The endpoint working with members supports filtering on numerous criteria, for example:

### Filtering by user.name exact match:
```swift
let memberListController = chatClient.memberListController( 
    query: .init(
        cid: .init(type: .messaging, id: "general"),
        filter: .equal(.name, to: "Lando") // will only match members with name "Lando"
    )
) 
```

### Filtering by part of the user.name

```swift
let memberListController = chatClient.memberListController( 
    query: .init(
        cid: .init(type: .messaging, id: "general"),
        filter: .query(.name, text: "an") // Returns Lando, Conan, any name with "an"
    ) 
) 
```

### Autocompleting members by user.name

```swift
let memberListController = chatClient.memberListController( 
    query: .init(
        cid: .init(type: .messaging, id: "general"),
        filter: .autocomplete(.name, text: "La") // Returns all the members with names starting with "La"
    ) 
) 
```

### Querying single a member by id

`ChatChannelMemberController` is an entity that allows to work with and observe changes for a specific member.
It has convenience methods for banning and unbanning a member.

```swift
let memberController = chatClient.memberController(
    userId: "user-id",
    in: .init(type: .messaging, id: "general")
)

// Ban a member for 10 minutes
memberController.ban(for: 10, reason: "spam")
memberController.unban()
```

### Querying several members by id

```swift
let memberListController = chatClient.memberListController( 
    query: .init(
        cid: .init(type: .messaging, id: "general"),
        filter: .in(.id, values: ["first-user", "second-user"])
    ) 
) 
```

### Querying channel moderators 

```swift
let memberListController = chatClient.memberListController( 
    query: .init(
        cid: .init(type: .messaging, id: "general"),
        filter: .equal(.isModerator, to: true)
    )
) 
```

### Querying banned members

```swift
let memberListController = chatClient.memberListController( 
    query: .init(
        cid: .init(type: .messaging, id: "general"),
        filter: .equal(.isBanned, to: true)
    ) 
) 
```

## Pagination and ordering

Since there potentially can be large amount of members in a channel, querying members supports pagination.
By default members are ordered from oldest to newest and can be paginated using offset-based pagination:

```swift
memberListController.loadNextMembers(limit: 10) { error in 
    // handle error / access members 
    print(error ?? memberListController.members) 
}
```

## Adding/removing members

```swift
let controller = chatClient.channelController(for: .init(type: .messaging, id: "general")) 
controller.addMembers(userIds: ["lando", "ann"]) 
controller.removeMembers(userIds: ["raya"])
```

:::caution
You can only add/remove up to 100 members at once.
:::

### Leaving a channel

Leaving a channel is the same as removing members from a channel, but it's called with the current user id:

```swift
let controller = chatClient.channelController(
    for: .init(type: .messaging, id: "general")
) 
controller.removeMembers(userIds: ["current-user-id"])
```

## Observing changes to members

Set the delegate of `ChatChannelMemberListController` to observe the changes in the system.

### Using delegate
```swift
class Controller: ChatChannelMemberListControllerDelegate {
    let memberListController: ChatChannelMemberListController

    init() {
        memberListController = chatClient.memberListController( 
            query: .init(cid: .init(type: .messaging, id: "general"), filter: .none) 
        )
        memberListController.delegate = self
    }

    func memberListController(
        _ controller: ChatChannelMemberListController,
        didChangeMembers changes: [ListChange<ChatChannelMember>]
    ) {
        // process changes
    }
}
```

### Using Combine publishers

```swift
let memberListController = chatClient.memberListController( 
    query: .init(cid: .init(type: .messaging, id: "general"), filter: .equal(.name, to: "Lando"))
)
// Subscribe for controller state changes
memberListController
    .statePublisher
    .sink(receiveValue: { print($0) })
    .store(in: &cancellables)

// Subscribe for members changes
memberListController
    .memberChangePublisher
    .sink(receiveValue: { print($0) })
    .store(in: &cancellables)
```

### SwiftUI Wrappers

`ChatChannelMemberListController` is fully compatible with SwiftUI:

```swift
struct MemberListView: View {
    @StateObject var memberList: ChatChannelMemberListController.ObservableObject
    
    var body: some View {
        VStack {
            List(memberList.members, id: \.self) { member in
                HStack {
                    Text(member.name ?? "Unknown")
                    Text(member.userRole.rawValue)
                }
            }
        }
        .onAppear {
            // call `synchronize()` to update the locally cached data.
             memberList.controller.synchronize() 
        }
        .navigationBarTitle(Text("Members"))
    }
}
```