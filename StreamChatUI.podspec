Pod::Spec.new do |spec|
  spec.name = "StreamChatUI"
  spec.version = "4.20.0"
  spec.summary = "StreamChat UI Components"
  spec.description = "StreamChatUI SDK offers flexible UI components able to display data provided by StreamChat SDK."

  spec.homepage = "https://getstream.io/chat/"
  spec.license = { :type => "BSD-3", :file => "LICENSE" }
  spec.author = { "getstream.io" => "support@getstream.io" }
  spec.social_media_url = "https://getstream.io"

  spec.swift_version = "5.2"
  spec.platform = :ios, "11.0"
  spec.requires_arc = true

  spec.framework = "Foundation", "UIKit"

  spec.module_name = "StreamChatUI"
  spec.source = { :git => "https://github.com/GetStream/stream-chat-swift.git", :tag => "#{spec.version}" }
  spec.source_files  = ["Sources/StreamChatUI/**/*.swift", "Sources/StreamNuke/**/*.swift", "Sources/StreamSwiftyGif/**/*.swift"]
  spec.resource_bundles = { "StreamChatUIResources" => ["Sources/StreamChatUI/Resources/**/*"] }

  spec.dependency "StreamChat", "#{spec.version}"
end
