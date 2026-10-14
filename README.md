# opencode-power-dev.app

Runs [OpenCode](https://opencode.ai) with [opencode-power-dev](https://github.com/M4jor-Tom/opencode-power-dev), the shared native OpenCode development profile.

```bash
nix run github:M4jor-Tom/opencode-power-dev.app -- [OpenCode arguments...]
```

On first run it clones the writable profile to `~/.opencode-power-dev`. Later runs fast-forward only a clean Git checkout whose origin exactly matches this profile's HTTPS URL. Dirty trees and unrelated directories are never pulled; a failed pull leaves the checkout intact. Set `OPENCODE_POWER_DEV_DIR` to use another location. The caller's project directory and OpenCode arguments pass through unchanged. For local, unpublished config checkouts, **set this override** instead of cloning the currently empty public origin.

Without Nix, install OpenCode >=1.18.29, Node 24, Git and jq, then run the profile's `scripts/run.sh` directly. That script installs pinned skill assets, isolates profile state and runs OpenCode; it does not copy credentials or disable native permission prompts. OpenCode's home/project discovery means this is not a sandbox. See the profile README for native feature limitations.

The Nix app supplies `opencode git gh glab nodejs bun ripgrep fd jq yq-go uv python3 rtk graphify markitdown pandoc poppler-utils yt-dlp`. `playwright-driver` is deliberately absent: the browser skill installs `@playwright/cli` through npm. Nixpkgs ships graphify at its own version; `uv` is included for the skill's own tool installation. Launch tests: `bash tests/launcher.sh opencode-power-dev`.
