MAKEFLAGS += --silent

bootstrap:
	./Scripts/bootstrap.sh

frameworks:
	bundle exec fastlane build_xcframeworks
	cd ./Products && zip -r "../BuiltArtifacts/StreamChat-All.zip" ./*.xcframework

update_dependencies:
	echo "♦︎♦︎♦︎ Updating Nuke ♦︎♦︎♦︎"
	make update_nuke version=10.3.3
	echo "♦︎♦︎♦︎ Updating Starscream ♦︎♦︎♦︎"
	make update_starscream version=4.0.4
	echo "♦︎♦︎♦︎ Updating SwiftyGif ♦︎♦︎♦︎"
	make update_swiftygif version=5.4.0

update_nuke: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/Nuke Sources/StreamNuke Sources
	./Scripts/removePublicDeclaracions.sh Sources/StreamNuke

update_starscream: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/Starscream Sources/StreamStarscream Sources
	./Scripts/removePublicDeclaracions.sh Sources/StreamStarscream

update_swiftygif: check_version_parameter
	./Scripts/updateDependency.sh $(version) Dependencies/SwiftyGif Sources/StreamSwiftyGif SwiftyGif
	./Scripts/removePublicDeclaracions.sh Sources/StreamSwiftyGif

check_version_parameter:
	@if [ "$(version)" = "" ]; then\
		echo "✕ Missing parameter"; \
        exit 1;\
    fi