cask "droppy" do
  version "1.2.4"
  sha256 "bbeef26b87cd7d4a547c631845155e0e06df998d97e1e4d5baf599bf0bbd5cf7"

  url "https://raw.githubusercontent.com/iordv/Droppy/main/Droppy.dmg"
  name "Droppy"
  desc "Drag and drop file shelf for macOS"
  homepage "https://github.com/iordv/Droppy"

  app "Droppy.app"

  zap trash: [
    "~/Library/Application Support/Droppy",
    "~/Library/Preferences/iordv.Droppy.plist",
  ]
end
