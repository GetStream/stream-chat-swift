MAKEFLAGS += --silent

bootstrap:
	./Scripts/bootstrap.sh

all_artifacts:
	echo "🏁 Starting at $$(date +%T)"
	make frameworks
	echo "🏁 Finished creating dynamic libraries at $$(date +%T)"
	make static_libraries
	echo "🏁 Finished creating static libraries at $$(date +%T)"
	open ./Products
	echo "🏁 Ended at $$(date +%T)"

frameworks: clean
	echo "👉 Creating dynamic libraries. Will take a while... Logs available: DerivedData/fastlane.log"
	bundle exec fastlane build_xcframeworks > DerivedData/fastlane.log
	echo "👉 Creating compressed archives"
	cp ./LICENSE ./Products/LICENSE
	make zip_artifacts name="StreamChat-All" pattern=./*.xcframework
	make zip_artifacts name="StreamChat" pattern="./StreamChat.xcframework ./LICENSE"
	make zip_artifacts name="StreamChatUI" pattern="./StreamChatUI.xcframework ./LICENSE"
	make swiftpm_checksum
	make clean

static_libraries: clean
	echo "👉 Creating static libraries"
	./Scripts/buildStaticLibraries.sh
	echo "👉 Creating compressed archive"
	make zip_artifacts name="StreamChat-All-Static" pattern='./*.xcframework ./*.bundle'
	make clean

clean:
	echo "♻️  Cleaning ./Products & ./DerivedData"
	rm -rf DerivedData
	mkdir -p DerivedData
	rm -rf Products/*.xcframework
	rm -rf Products/*.bundle
	rm -rf Products/*.BCSymbolMaps
	rm -rf Products/*.dSYMs
	rm Products/LICENSE || true

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

swiftpm_checksum:
	echo "ℹ️  Checksum for StreamChat.zip"
	swift package compute-checksum Products/StreamChat.zip
	echo "ℹ️  Checksum for StreamChatUI.zip"
	swift package compute-checksum Products/StreamChatUI.zip

update_dependencies:
	echo "👉 Updating Nuke"
	make update_nuke version=10.3.3
	echo "👉 Updating Starscream"
	make update_starscream version=4.0.4
	echo "👉 Updating SwiftyGif"
	make update_swiftygif version=5.4.2

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
		echo "❌ Missing version parameter"; \
        exit 1;\
    fi
