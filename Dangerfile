skip_danger_check = github.pr_body.include? "#skip_danger"

if skip_danger_check
    message("Skipping Danger due to skip_danger tag")
    return
end

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet.
if github.pr_json["mergeable_state"] == "draft"
    message("Skipping Danger since PR is classed as Draft")
    return
end

# Warn when there is a big PR.
warn("Big PR") if git.lines_of_code > 500

# Mainly to encourage writing up some reasoning about the PR, rather than just leaving a title.
if github.pr_body.length < 3 && git.lines_of_code > 50
    warn("Please provide a summary in the Pull Request description")
end

## Let's check if there are any changes in the project folder
has_app_changes = !git.modified_files.grep(/Sources/).empty?

## Then, we should check if tests are updated
# has_test_changes = !git.modified_files.grep(/StreamChatCoreTests/).empty?

# if has_app_changes && !has_test_changes
#     warn("Please adds tests!")
# end

has_meta_label = github.pr_labels.any? { |label| label.include? "meta" }
has_demo_label = github.pr_labels.any? { |label| label.include? "demo" }
has_no_changelog_tag = github.pr_body.include? "#no_changelog"
has_skip_changelog_tag = github.pr_body.include? "#skip_changelog"

has_changelog_escape = has_meta_label || has_demo_label || has_no_changelog_tag || has_skip_changelog_tag

# Add a CHANGELOG entry for app changes
if !has_changelog_escape && !git.modified_files.include?("CHANGELOG.md") && has_app_changes
    message("There seems to be app changes but CHANGELOG wasn't modified.\nPlease include an entry if the PR includes user-facing changes.\nYou can find it at [CHANGELOG.md](https://github.com/GetStream/stream-chat-swift/blob/main/CHANGELOG.md).")
end

# Check all commits have correct format. Disable the length rule, since it's hardcoded
# to 50 and GitHub has the limit 80.
commit_lint.check disable: [:subject_length]