# CI runners

Smoke Checks uses the `stream-macos` runner group for macOS jobs. Guard and
E2E result checks use GitHub-hosted Ubuntu runners. Other workflows keep their
existing runner selection.

## Run PR checks

1. Give this repository access to the `stream-macos` runner group. The group
   must allow public repositories.
2. Use the prepared Stream macOS image with an ephemeral VM for each job.
3. Open a PR, or select **Actions → Smoke Checks → Run workflow** on your branch.

There is no self-hosted input. Shell scripts read `RUNNER_ENVIRONMENT`.
Composite actions use the equivalent `runner.environment` context.

## Reuse the image

- Ruby setup uses Mise's Ruby 3.1.7 and the warmed Chat gem bundle at
  `~/.local/share/stream-macos-image/project-caches/stream-chat-swift/bundle`.
  Bundler installs missing dependencies from `Gemfile.lock`.
- SPM setup links `spm_cache` to `SPM_CACHE_PATH` when that directory exists.
  Otherwise, it creates an empty checkout-local cache. It does not replace
  an unrelated existing directory.
- Bootstrap reuses matching tools. It installs missing or mismatched tools.
- Simulator setup reuses available runtimes and devices. It installs or creates
  only what is missing.

GitHub-hosted jobs keep remote Ruby and SPM caching. Self-hosted jobs skip those
remote caches. UI, Common UI, and E2E jobs still download build products from
Build Test App and Frameworks. Each job runs in a separate VM, so those products
must be transferred. Demo builds and SPM integration build independently.

Test jobs upload raw Xcode logs on success and failure. Download the
`xcode-logs-*` artifact from the workflow run to inspect the unformatted output.
