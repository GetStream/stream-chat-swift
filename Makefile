MAKEFLAGS += --silent

bootstrap:
	./Scripts/bootstrap.sh

generate:
	sourcery --config Sources/StreamChat/.sourcery.yml

all_artifacts:
	echo "🏁 Starting at $$(date +%T)"
	make frameworks
	echo "🏁 Finished creating dynamic libraries at $$(date +%T)"
	make static_libraries
	echo "🏁 Finished creating static libraries at $$(date +%T)"
	open ./Products
	echo "🏁 Ended at $$(date +%T)"

frameworks: clean
	echo "👉 Creating dynamic libraries. Will take a while... Logs available: fastlane/fastlane.log"
	bundle exec fastlane build_xcframeworks > fastlane/fastlane.log
	bundle exec fastlane compress_frameworks
	make clean

static_libraries: clean
	echo "👉 Creating static libraries"
	./Scripts/buildStaticLibraries.sh
	echo "👉 Creating compressed archive"
	make zip_artifacts name="StreamChat-All-Static" pattern='./*.xcframework ./*.bundle'
	make clean

clean:
	echo "♻️ Cleaning ./Products"
	bundle exec fastlane clean_products

zip_artifacts:
	@if [ "$(name)" = "" ]; then\
		echo "❌ Missing name parameter"; \
        exit 1;\
    fi
	@if [ "$(pattern)" = "" ]; then\
		echo "❌ Missing pattern parameter"; \
        exit 1;\
    fi
	echo "👉 Compressing $(name)"
	cd ./Products && zip -r "$(name).zip" $(pattern) > /dev/null

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
