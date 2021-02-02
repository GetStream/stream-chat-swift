Pod::Spec.new do |spec|
  spec.name = "StreamChat"
  spec.version = "3.0.1"
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

  spec.source_files  = "Sources/StreamChat/**/*.swift"
  spec.exclude_files = ["Sources/StreamChat/**/*_Tests.swift", "Sources/StreamChat/**/*_Mock.swift"]
  spec.resources = ["Sources/StreamChat/**/*.xcdatamodeld"]

  spec.framework = "Foundation", "UIKit"

  spec.dependency "Starscream", "~> 4.0"
end
