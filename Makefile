MAKEFLAGS += --silent

bootstrap:
	./Scripts/bootstrap.sh

generate:
	sourcery --config Sources/StreamChat/.sourcery.yml

update_dependencies:
	echo "👉 Updating DifferenceKit"
	make update_differencekit version=1.3.0

update_differencekit: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/DifferenceKit Sources/StreamChatUI/StreamDifferenceKit Sources
	./Scripts/removePublicDeclarations.sh Sources/StreamChatUI/StreamDifferenceKit

check_version_parameter:
	@if [ "$(version)" = "" ]; then\
		echo "❌ Missing version parameter"; \
        exit 1;\
    fi
