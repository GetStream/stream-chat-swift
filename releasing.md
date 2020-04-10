# Releasing

### Tools
- Cocoapods for project dependencies: `sudo gem install cocoapods`
- Jazzy for docs: `sudo gem install jazzy`

### Install the project
- Check out the project: `https://github.com/GetStream/stream-chat-swift.git`
- Install pods: `pod install`

### Releasing
1. Open the project in Xcode
2. Bump the version and build number of the project:
  - Project StreamChat → Target `StreamChatClient` → General → Version `2.0.0`
  - Project StreamChat → Target `StreamChatCore` → General → Version `2.0.0`
  - Project StreamChat → Target `StreamChat` → General → Version `2.0.0`
3. Open `StreamChatClient.podspec`, `StreamChatCore.podspec` and `StreamChat.podspec` files and update the version to the same as on the Xcode project: `spec.version = "2.0.0"`
4. Commit changes to the repo as `Bump v.2.0.0`
5. Add the tag `2.0.0` to the repo and push it to the origin.
6. Update docs:
  - `jazzy --podspec StreamChatClient.podspec --output docs/client -a GetStream.io -u getstream.io -g https://github.com/GetStream/stream-chat-swift`
  - `jazzy --podspec StreamChatCore.podspec --output docs/code -a GetStream.io -u getstream.io -g https://github.com/GetStream/stream-chat-swift`
  - `jazzy --podspec StreamChat.podspec --output docs/ui -a GetStream.io -u getstream.io -g https://github.com/GetStream/stream-chat-swift`
8. Commit updated docs to the repo.
9. Add release notes: https://github.com/GetStream/stream-chat-swift/releases
10. Push the release to the Cocoapods: 
  - `pod trunk push StreamChatColient.podspec`
  - `pod trunk push StreamChatCore.podspec`
  - `pod trunk push StreamChat.podspec`

```
--------------------------------------------------------------------------------
 🎉  Congrats

 🚀  StreamChat (2.0.0) successfully published
 📅  April 2nd, 18:41
 🌎  https://cocoapods.org/pods/StreamChat
 👍  Tell your friends!
--------------------------------------------------------------------------------
```
