#!/bin/bash

# SANDBOX FILE: For iOS testing/development. See .cursorrules.
# Script to create Xcode project programmatically with proper structure
# Purpose: Automate Xcode project creation for Jarvis Live Sandbox

set -e

PROJECT_ROOT="/Users/bernhardbudiono/Library/CloudStorage/Dropbox/_Documents - Apps (Working)/repos_github/Working/repo_jarvis_live"
IOS_DIR="$PROJECT_ROOT/_iOS"
SANDBOX_DIR="$IOS_DIR/JarvisLive-Sandbox"

echo "Creating Jarvis Live Sandbox Xcode project..."

# Create project using xcodegen if available, otherwise use manual creation
if command -v xcodegen &> /dev/null; then
    echo "Using xcodegen to create project..."
    # Create project.yml for xcodegen
    cat > "$SANDBOX_DIR/project.yml" << EOF
name: JarvisLive-Sandbox
options:
  bundleIdPrefix: com.ablankcanvas
  developmentLanguage: en
  deploymentTarget:
    iOS: "16.0"

targets:
  JarvisLive-Sandbox:
    type: application
    platform: iOS
    sources:
      - JarvisLive-Sandbox
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ablankcanvas.JarvisLive.Sandbox
        DEVELOPMENT_TEAM: ""
        INFOPLIST_FILE: JarvisLive-Sandbox/Info.plist
        DEVELOPMENT_ASSET_PATHS: "JarvisLive-Sandbox/Preview Content"
        ENABLE_PREVIEWS: YES
        INFOPLIST_KEY_NSMicrophoneUsageDescription: "Jarvis Live needs microphone access for voice interaction"
        INFOPLIST_KEY_NSCameraUsageDescription: "Jarvis Live needs camera access for document scanning and visual analysis"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        SWIFT_EMIT_LOC_STRINGS: YES
        SWIFT_VERSION: "5.0"
        TARGETED_DEVICE_FAMILY: "1,2"

  JarvisLiveTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - JarvisLiveTests
    dependencies:
      - target: JarvisLive-Sandbox
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ablankcanvas.JarvisLiveTests
        SWIFT_EMIT_LOC_STRINGS: NO

  JarvisLiveUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - JarvisLiveUITests
    dependencies:
      - target: JarvisLive-Sandbox
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ablankcanvas.JarvisLiveUITests
        SWIFT_EMIT_LOC_STRINGS: NO
        TEST_TARGET_NAME: JarvisLive-Sandbox
EOF

    cd "$SANDBOX_DIR"
    xcodegen generate
else
    echo "xcodegen not found. Using Xcode command line tools..."
    # Create using swift package init as fallback
    cd "$SANDBOX_DIR"
    
    # Create a basic Package.swift for the iOS app
    cat > Package.swift << EOF
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "JarvisLive-Sandbox",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "JarvisLive-Sandbox", targets: ["JarvisLive-Sandbox"])
    ],
    targets: [
        .target(name: "JarvisLive-Sandbox"),
        .testTarget(name: "JarvisLiveTests", dependencies: ["JarvisLive-Sandbox"])
    ]
)
EOF
fi

echo "Xcode project creation completed!"
echo "Location: $SANDBOX_DIR"

# Make the script executable
chmod +x "$0"