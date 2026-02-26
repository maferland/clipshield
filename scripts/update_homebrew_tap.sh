#!/bin/bash
set -euo pipefail

VERSION="${1:?Usage: update_homebrew_tap.sh VERSION DMG_PATH}"
DMG_PATH="${2:?Usage: update_homebrew_tap.sh VERSION DMG_PATH}"

if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG not found at $DMG_PATH"
    exit 1
fi

SHA=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
CASK_VERSION="${VERSION#v}"

echo "Updating homebrew tap: version=$CASK_VERSION sha256=$SHA"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

gh repo clone maferland/homebrew-tap "$WORK_DIR" -- --depth 1

if [ -n "${GH_TOKEN:-}" ]; then
    git -C "$WORK_DIR" remote set-url origin "https://x-access-token:${GH_TOKEN}@github.com/maferland/homebrew-tap.git"
fi

CASK_FILE="$WORK_DIR/Casks/clipshield.rb"

cat > "$CASK_FILE" << CASK
cask "clipshield" do
  version "$CASK_VERSION"
  sha256 "$SHA"

  url "https://github.com/maferland/clipshield/releases/download/v#{version}/ClipShield-v#{version}-macos.dmg"
  name "ClipShield"
  desc "Auto-clear sensitive data from your macOS clipboard"
  homepage "https://github.com/maferland/clipshield"

  depends_on macos: ">= :sonoma"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "ClipShield.app"

  zap trash: "~/Library/Preferences/com.maferland.clipshield.plist"
end
CASK

cd "$WORK_DIR"
git add Casks/clipshield.rb
git commit -m "Update clipshield to $VERSION"
git push

echo "Homebrew tap updated"
