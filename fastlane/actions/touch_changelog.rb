module Fastlane
  module Actions
    class TouchChangelogAction < Action
      def self.run(params)
        changelog_path = params[:changelog_path] unless params[:changelog_path].to_s.empty?
        release_version = params[:release_version] unless params[:release_version].to_s.empty?

        UI.message("Starting to update '#{changelog_path}'")

        file_data = File.readlines(changelog_path)
        upcoming_line = -1
        changes_since_last_release = ''

        File.open(changelog_path).each.with_index do |line, index|
          if upcoming_line != -1
            if line.start_with?('# [')
              break
            else
              changes_since_last_release += line
            end
          elsif line == "# Upcoming\n"
            upcoming_line = index
          end
        end

        file_data[upcoming_line] = "# [#{release_version}](https://github.com/GetStream/stream-chat-swift/releases/tag/#{release_version})"

        today = Time.now.strftime('%B %d, %Y')
        file_data.insert(upcoming_line + 1, "_#{today}_")
        file_data.insert(upcoming_line, '# Upcoming')
        file_data.insert(upcoming_line + 1, '')
        file_data.insert(upcoming_line + 2, '### 🔄 Changed')
        file_data.insert(upcoming_line + 3, '')

        # Write updated content to file
        changelog = File.open(changelog_path, 'w')
        changelog.puts(file_data)
        changelog.close
        UI.success("Successfully updated #{changelog_path}")
        return changes_since_last_release
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Updates CHANGELOG.md file with release'
      end

      def self.details
        'Use this action to rename your unrelease section to your release version and add a new unreleased section to your project CHANGELOG.md'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :changelog_path,
                                       env_name: 'FL_CHANGELOG_PATH',
                                       description: 'The path to your project CHANGELOG.md',
                                       is_string: true,
                                       default_value: './CHANGELOG.md',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :release_version,
                                       env_name: 'FL_CHANGELOG_RELEASE_VERSION',
                                       description: 'The release version, according to semantic versioning',
                                       is_string: true,
                                       default_value: '',
                                       optional: false)
        ]
      end

      def self.authors
        ['b-onc']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
