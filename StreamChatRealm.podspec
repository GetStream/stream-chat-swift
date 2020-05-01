Pod::Spec.new do |spec|
  spec.name = "StreamChatRealm"
  spec.version = "0.0.1"
  spec.summary = "Stream iOS Chat Realm"
  spec.description = "stream-chat-swift is the official Swift client for Stream Chat, a service for building chat applications."

  spec.homepage = "https://getstream.io/chat/"
  spec.license = { :type => "BSD-3", :file => "LICENSE" }
  spec.author = { "Alexey Bukhtin" => "alexey@getstream.io" }
  spec.social_media_url = "https://getstream.io"
  spec.swift_version = "5.0"
  spec.platform = :ios, "11.0"
  spec.source = { :git => "https://github.com/GetStream/stream-chat-swift.git", :tag => "#{spec.version}" }
  spec.requires_arc = true

  spec.source_files  = "Sources/Database/Realm/**/*.swift"

  spec.framework = "Foundation"

  spec.dependency "StreamChatCore", "#{spec.version}"
  spec.dependency "RealmSwift"
end
