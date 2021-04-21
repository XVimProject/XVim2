#!/bin/sh

XCODE_VERSION=$(xcodebuild -version | head -1 | cut -f2 -d" ")
defaults write com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-${XCODE_VERSION} '{ allowed = { "net.JugglerShu.XVim2" = { version = 1; }; }; skipped = {}; }'
