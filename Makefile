MAKEFLAGS += --silent

bootstrap:
	./Scripts/bootstrap.sh

frameworks:
	echo "♦︎♦︎♦︎ Creating xcframeworks ♦︎♦︎♦︎"
	bundle exec fastlane build_xcframeworks
	echo "♦︎♦︎♦︎ Creating compressed archives ♦︎♦︎♦︎"
	cd ./Products && zip -r "StreamChat-All.xcframework.zip" ./*.xcframework
	cd ./Products && zip -r "StreamChat.xcframework.zip" ./StreamChat.xcframework
	cd ./Products && zip -r "StreamChatUI.xcframework.zip" ./StreamChatUI.xcframework
	echo "♦︎♦︎♦︎ Checksum for StreamChat.xcframework.zip ♦︎♦︎♦︎"
	swift package compute-checksum Products/StreamChat.xcframework.zip
	echo "♦︎♦︎♦︎ Checksum for StreamChatUI.xcframework.zip ♦︎♦︎♦︎"
	swift package compute-checksum Products/StreamChatUI.xcframework.zip

update_dependencies:
	echo "♦︎♦︎♦︎ Updating Nuke ♦︎♦︎♦︎"
	make update_nuke version=10.3.3
	echo "♦︎♦︎♦︎ Updating Starscream ♦︎♦︎♦︎"
	make update_starscream version=4.0.4
	echo "♦︎♦︎♦︎ Updating SwiftyGif ♦︎♦︎♦︎"
	make update_swiftygif version=5.4.0

update_nuke: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/Nuke Sources/StreamChatUI/StreamNuke Sources
	./Scripts/removePublicDeclaracions.sh Sources/StreamChatUI/StreamNuke

update_starscream: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/Starscream Sources/StreamChat/StreamStarscream Sources
	./Scripts/removePublicDeclaracions.sh Sources/StreamChat/StreamStarscream

update_swiftygif: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/SwiftyGif Sources/StreamChatUI/StreamSwiftyGif SwiftyGif
	./Scripts/removePublicDeclaracions.sh Sources/StreamChatUI/StreamSwiftyGif

check_version_parameter:
	@if [ "$(version)" = "" ]; then\
		echo "✕ Missing parameter"; \
        exit 1;\
    fi