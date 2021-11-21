Pod::Spec.new do |spec|
  spec.name = "StreamChatUI"
  spec.version = "4.5.0"
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

  spec.source = { :http => "https://github.com/GetStream/stream-chat-swift/releases/download/#{spec.version}/#{spec.name}.xcframework.zip" }
  spec.vendored_frameworks = "#{spec.name}.xcframework"
  spec.preserve_paths = "#{spec.name}.xcframework/*"

  spec.dependency "StreamChat", "#{spec.version}"
end