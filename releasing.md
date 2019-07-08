# Releasing

### Tools
- Cocoapods for project dependencies: `sudo gem install cocoapods`
- Jazzy for docs: `sudo gem install jazzy`

### Install the project
- Check out the project: `https://github.com/GetStream/stream-chat-swift.git`
- Install pods: `pod install`

### Releasing
1. Open the project in Xcode
2. Update the version and build number of the project:
  - Project StreamChat → Target StreamChat → General → Version `1.0.0`
  - Project StreamChat → Target StreamChat → General → Build (for the beta testing) `+1`
3. Open `StreamChat.podspec` file and update the version to the same as on the Xcode project: `spec.version = "1.0.0"`
4. Commit changes to the repo as `Bump v.1.0.0`
5. Add the tag `1.0.0` to the repo and push it to the origin.
6. Update docs: `jazzy --podspec StreamChat.podspec -a GetStream.io -u getstream.io -g https://github.com/GetStream/stream-chat-swift`
7. Commit updated docs to the repo.
8. Add release notes: https://github.com/GetStream/stream-chat-swift/releases
9. Push the release to the Cocoapods: `pod trunk push GetStream.podspec`

```
--------------------------------------------------------------------------------
 🎉  Congrats

 🚀  StreamChat (1.0.0) successfully published
 📅  July 8th, 11:47
 🌎  https://cocoapods.org/pods/StreamChat
 👍  Tell your friends!
--------------------------------------------------------------------------------
```
