---
name: Release Template
about: Template for creating release tasks.
title: Release [VERSION]
labels: ''
assignees: ''

---

Useful docs:

[QA Testing Strategy](https://www.notion.so/stream-chat-fe-sdk/QA-Testing-186bcce43d8244cabbc0200a28499cf1)
[Releasing The SDKs](https://www.notion.so/stream-chat-fe-sdk/SDLC-b8ae212f53124fc3b183407cf995ea44#4649ba090aa8454f90696999a4efca99)
[Release Pipeline Docs on Notion](https://www.notion.so/stream-wiki/Release-Pipeline-fe5049ae09cd4302bb697e192047576e)

### TODOs:
Find more details about the TODOs after the checklist.
- [ ] Make sure all required work is already done and ready to be released
- [ ] Create release candidate
- [ ] QA the release
- [ ] Publish the Release
- [ ] Verify the integration (post-release step)
- [ ] Merge main to develop
- [ ] Review & eventually resolve the open tickets in Zendesk/Github/Slack
- [ ] Check and verify accuracy of Docusaurus documentation
- [ ] Verify sample apps and tutorial are still correct
- [ ] Announce the release in the team slack channel
- [ ] Preparing release notes tweets
- [ ] Loom release changelog

#### Make sure all required work is already done and ready to be released

1. Check that all required work has made it into the develop
2. Link any ongoing work (pull requests) that might block the release, to the release issue.
3. Get help from the team to propagate the required work to the main

#### Create release candidate

To create a new release candidate follow these steps:
1. Make sure you’re on develop and have pulled down the latest
2. Make sure you configure the Github Token, follow Prerequisite of the following guide: https://www.notion.so/stream-wiki/Release-Pipeline-fe5049ae09cd4302bb697e192047576e
3. Run the following command bundle exec fastlane release type:{patch/minor/major}
That is all that is required, you should now have a new PR open for the release

#### QA the release

1. [Run the QA session](https://www.notion.so/stream-wiki/Running-a-release-QA-on-Allure-TestOps-eace5d13a26840c89941bcd1d70bbfe3)
2. Create GH issue for every bug that you’ll find during the QA session

#### Publish the Release

```
bundle exec fastlane merge_release_to_main
```

#### Verify the integration (post-release step)

1. Clone the repo with integration apps: [GitHub - GetStream/stream-chat-swift-integration-apps: Integration apps for Stream Chat iOS SDK](https://github.com/GetStream/stream-chat-swift-integration-apps)
2. Run lane from the main branch: 
```
bundle install
GITHUB_TOKEN=your_github_token bundle exec fastlane test_release version:RELEASED_VERSION_NUMBER
```
3. You’ll be asked first to commit & then to push the changes (version bumps) to release branch (eg. release/4.6.0).
4. Once the lane finishes successfully, check the newly created release PR and get +1 approval from your release buddy
5. Merge the PR once all status checks will pass.

#### Merge main to develop

```
bundle exec fastlane merge_main_to_develop
```

#### Review & eventually resolve the open tickets in Zendesk/Github/Slack

For shipped bugfixes & features:
1. Respond in and close Zendesk tickets
2. Respond in and close Github issues with 🔜  Upcoming label
3. Respond in and lock Github discussions with 🔜  Upcoming label

#### Check and verify accuracy of Docusaurus documentation

Docusaurus automatically deploys to staging. So check everything there to see if things are still valid.
https://staging.getstream.io/chat/sdk/

Check for:
- Broken links
- Removed/moved pages, linked to from other areas/locations, update those references.
- Double check grammar/spelling even though this should already be reviewed on the individual pull requests to main branch.

#### Verify sample apps and tutorial are still correct

Are the sample apps still valid with the new SDK version

Check
Tutorial repos:
1. [ios-chat-tutorial](https://github.com/GetStream/ios-chat-tutorial) (credentials can be found [here](https://github.com/GetStream/stream-chat-swift/blob/develop/Stream.playground/Contents.swift))
2. [Tutorial articles](https://getstream.io/blog/topic/tutorials/), when following the tutorial, does every step still behave/compile as expected?
3. Run [Sample apps](https://github.com/GetStream/stream-chat-swift/tree/main/Examples) embedded in the source repos locally and verify they follow zero ⚠️ policy + can load the channel list/message list respectively. If you’ll find any issues please note them down in the comment section + notify the team:
- iMessage
- Messenger
- Slack
- YouTube

#### Announce the release in the team slack channel

Mention iOS team on slack with the message the release is done. Keep in mind that without the team mention, the release announcement can get unnoticed. Feel free to also add link towards the release message from #releases channel, eg: https://getstream.slack.com/archives/C01621AGH2N/p1645023467395749

#### Preparing release notes tweets

e.g. https://getstream.slack.com/archives/CRB9P6L03/p1666951504404039

#### Loom release changelog

- Loom the most important release changes
- include demo if possible
- Post it to the #releases channel in Slack
