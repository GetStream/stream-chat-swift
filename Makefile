MAKEFLAGS += --silent

bootstrap:
	./Scripts/bootstrap.sh

generate:
	sourcery --config Sources/StreamChat/.sourcery.yml

update_dependencies:
	echo "👉 Updating SwiftyGif"
	make update_swiftygif version=5.4.2
	echo "👉 Updating DifferenceKit"
	make update_differencekit version=1.3.0
	echo "👉 Updating Splash"
	make update_splash version=0.16.0
	echo "👉 Updating MarkdownUI"
	make update_markdownui version=2.4.0
	echo "👉 Updating NetworkImage"
	make update_networkimage version=6.0.1

update_swiftygif: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/SwiftyGif Sources/StreamChatUI/StreamSwiftyGif SwiftyGif
	./Scripts/removePublicDeclarations.sh Sources/StreamChatUI/StreamSwiftyGif

update_differencekit: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/DifferenceKit Sources/StreamChatUI/StreamDifferenceKit Sources
	./Scripts/removePublicDeclarations.sh Sources/StreamChatUI/StreamDifferenceKit

update_splash: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/Splash Sources/StreamChatAI/StreamSplash Sources/Splash
	./Scripts/removePublicDeclarations.sh Sources/StreamChatAI/StreamSplash

# MarkdownUI's Swift sources go into StreamChatAI, and its cmark-gfm C sources into their own target
update_markdownui: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/MarkdownUI Sources/StreamChatAI/StreamMarkdownUI Sources/MarkdownUI
	./Scripts/updateDependency.sh $(version) Dependencies/MarkdownUI Sources/StreamChatAICMark Sources/cmark-gfm
	./Scripts/removePublicDeclarations.sh Sources/StreamChatAI/StreamMarkdownUI
	./Scripts/prefixCSymbols.sh stream_ Sources/StreamChatAICMark Sources/StreamChatAI/StreamMarkdownUI

update_networkimage: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/NetworkImage Sources/StreamChatAI/StreamNetworkImage Sources/NetworkImage
	./Scripts/removePublicDeclarations.sh Sources/StreamChatAI/StreamNetworkImage

check_version_parameter:
	@if [ "$(version)" = "" ]; then\
		echo "❌ Missing version parameter"; \
        exit 1;\
    fi
