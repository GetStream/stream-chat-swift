import PlaygroundSupport
import UIKit
import StreamChat
import StreamChatUI

PlaygroundPage.current.needsIndefiniteExecution = true
/*:
 # Stream Playground
 Playground used for testing the StreamChat and StreamChatUI components of the SDK.

 ⚠️ Please, feel free to change the playground and test different components, but do not commit the changes.
*/
let apiKeyString = "8br4watad788"

LogConfig.level = .info

let client = ChatClient(
    config: .init(apiKeyString: apiKeyString)
)

let token: Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0"

client.connectUser(
    userInfo: UserInfo(
        id: "luke_skywalker",
        name: "Luke Skywalker"
    ),
    token: token
)

extension ChatUserAvatarView: CurrentChatUserControllerDelegate {
    public func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>) {
        content = controller.currentUser
    }
}

let view = ChatUserAvatarView()
view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)

let currentUserController = client.currentUserController()
currentUserController.delegate = view

currentUserController.synchronize()

PlaygroundPage.current.liveView = view
