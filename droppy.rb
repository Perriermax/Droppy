cask "droppy" do
  version "1.0"
  sha256 "b189900bf39f24b5ca259fb9fdd0260fa14972b42584224e0e0e6936e422079a"

  # Replace YOUR_GITHUB_USERNAME and YOUR_REPO_NAME with your actual GitHub details
  url "https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME/releases/download/v#{version}/Droppy.dmg"
  name "Droppy"
  desc "Drag and drop file shelf for macOS"
  homepage "https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME"

  app "Droppy.app"

  zap trash: [
    "~/Library/Application Support/Droppy",
    "~/Library/Preferences/iordv.Droppy.plist",
  ]
end
