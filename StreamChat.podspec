Pod::Spec.new do |spec|
  spec.name = "StreamChat"
  spec.version = "3.0-alpha"
  spec.summary = "StreamChat iOS Client"
  spec.description = "stream-chat-swift is the official Swift client for Stream Chat, a service for building chat applications."

  spec.homepage = "https://getstream.io/chat/"
  spec.license = { :type => "BSD-3", :file => "LICENSE" }
  spec.author = { "getstream.io" => "support@getstream.io" }
  spec.social_media_url = "https://getstream.io"
  spec.swift_version = "5.2"
  spec.platform = :ios, "11.0"
  spec.source = { :git => "https://github.com/GetStream/stream-chat-swift.git", :tag => "#{spec.version}" }
  spec.requires_arc = true

  spec.source_files  = "Sources_v3/**/*.swift"
  spec.exclude_files = ["Sources_v3/**/*_Tests.swift", "Sources_v3/**/*_Mock.swift"]

  spec.framework = "Foundation", "UIKit"

  spec.dependency "Starscream", "~> 3.1"
end
