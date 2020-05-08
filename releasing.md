# Releasing

### Tools

- Bundler for dependency management: `gem install bundler`

### Install the project

- Check out the project: `https://github.com/GetStream/stream-chat-swift.git`
- Install gems: `bundle install`
- Install Carthage: `bundle exec fastlane carthage_bootstrap`

### Releasing

You should have authority to push the podspec. Contact repo maintainers.

#### Automated

Run `bundle exec fastlane release` with argument `type`
- `patch` for x.x.1 release
- `minor` for x.1.x release
- `major` for 1.x.x release

#### Manual

(Using example version `2.0.0`)

1. Open the project in Xcode
1. Bump the version and build number of the project:
  - Project StreamChat → Target `StreamChatClient` → General → Version `2.0.0`
  - Project StreamChat → Target `StreamChatCore` → General → Version `2.0.0`
  - Project StreamChat → Target `StreamChat` → General → Version `2.0.0`
1. Open `StreamChatClient.podspec`, `StreamChatCore.podspec` and `StreamChat.podspec` files and update the version to the same as on the Xcode project: `spec.version = "2.0.0"`
1. Update docs:
  - `jazzy --podspec StreamChatClient.podspec --output docs/client -a GetStream.io -u getstream.io -g https://github.com/GetStream/stream-chat-swift`
  - `jazzy --podspec StreamChatCore.podspec --output docs/code -a GetStream.io -u getstream.io -g https://github.com/GetStream/stream-chat-swift`
  - `jazzy --podspec StreamChat.podspec --output docs/ui -a GetStream.io -u getstream.io -g https://github.com/GetStream/stream-chat-swift`
1. Commit changes as `Bump 2.0.0`
1. Add the tag `2.0.0` to commit
1. Push changes to repo, alongside the tag
1. Add release notes: https://github.com/GetStream/stream-chat-swift/releases
1. Push the release to the Cocoapods: 
  - `pod trunk push StreamChatClient.podspec --allow-warnings`
  - `pod trunk push StreamChatCore.podspec --allow-warnings`
  - `pod trunk push StreamChat.podspec --allow-warnings`

```
--------------------------------------------------------------------------------
 🎉  Congrats

 🚀  StreamChat (2.0.0) successfully published
 📅  April 2nd, 18:41
 🌎  https://cocoapods.org/pods/StreamChat
 👍  Tell your friends!
--------------------------------------------------------------------------------
```
