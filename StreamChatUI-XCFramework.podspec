Pod::Spec.new do |spec|
  spec.name = "StreamChatUI-XCFramework"
  spec.version = "4.19.0"
  spec.summary = "StreamChat UI Components"
  spec.description = "StreamChatUI SDK offers flexible UI components able to display data provided by StreamChat SDK."

  spec.homepage = "https://getstream.io/chat/"
  spec.license = { :type => "BSD-3", :file => "LICENSE" }
  spec.author = { "getstream.io" => "support@getstream.io" }
  spec.social_media_url = "https://getstream.io"

  spec.swift_version = "5.5"
  spec.platform = :ios, "11.0"
  spec.requires_arc = true

  spec.framework = "Foundation", "UIKit"

  spec.module_name = "StreamChatUI"
  spec.source = { :http => "https://github.com/GetStream/stream-chat-swift/releases/download//#{spec.version}/#{spec.module_name}.zip" }
  spec.vendored_frameworks = "#{spec.module_name}.xcframework"
  spec.preserve_paths = "#{spec.module_name}.xcframework/*"

  spec.dependency "StreamChat-XCFramework", "#{spec.version}"

  spec.cocoapods_version = ">= 1.11.0"
end
