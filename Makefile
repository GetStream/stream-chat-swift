MAKEFLAGS += --silent

bootstrap:
	./Scripts/bootstrap.sh

update_dependencies:
	echo "👉 Updating Nuke"
	make update_nuke version=10.3.3
	echo "👉 Updating SwiftyGif"
	make update_swiftygif version=5.4.2
	echo "👉 Updating DifferenceKit"
	make update_differencekit version=1.3.0

update_nuke: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/Nuke Sources/StreamChatUI/StreamNuke Sources
	./Scripts/removePublicDeclarations.sh Sources/StreamChatUI/StreamNuke

update_swiftygif: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/SwiftyGif Sources/StreamChatUI/StreamSwiftyGif SwiftyGif
	./Scripts/removePublicDeclarations.sh Sources/StreamChatUI/StreamSwiftyGif

update_differencekit: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/DifferenceKit Sources/StreamChatUI/StreamDifferenceKit Sources
	./Scripts/removePublicDeclarations.sh Sources/StreamChatUI/StreamDifferenceKit

check_version_parameter:
	@if [ "$(version)" = "" ]; then\
		echo "❌ Missing version parameter"; \
        exit 1;\
    fi
