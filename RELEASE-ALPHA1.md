# jellypig tvOS Alpha 1 Release

**Release Date**: October 17, 2025
**Base Version**: Swiftfin 1.3
**Branch**: jellypig-1.3
**License**: MPL-2.0

---

## Overview

jellypig is a personal fork of [Jellyfin/Swiftfin](https://github.com/jellyfin/swiftfin) optimized for tvOS with specialized support for Jellyfin.Xtream plugin content. This alpha1 release represents a stable, working build that plays everything upstream Swiftfin on tvOS plays **and more**, with an elegant native UI maintained by the Swiftfin development team.

## Key Features

### ✅ What Works
- **Full Jellyfin Playback**: All standard Jellyfin content (movies, series, live TV) plays correctly
- **Xtream Content Support**: Properly displays and plays Xtream VOD and Series content from Jellyfin.Xtream plugin
- **Channel Navigation**: Fixed channel browsing with proper grid view for categories and content
- **Full-Screen Navigation**: All views display full-screen (no modal popups)
- **Video Playback Controls**: ESC key properly shows controls and allows exit with confirmation
- **Native UI**: Maintains the elegant, native tvOS interface from upstream Swiftfin

### 🎯 Major Improvements Over Upstream
1. **Xtream Content Listing**: Fixed channel folder navigation to use proper Jellyfin Channel API endpoints
   - Xtream VOD and Xtream Series channels now display correct, distinct content
   - Channel folders display in grid view matching library behavior

2. **tvOS Navigation Architecture**: Restructured routing to fix modal popup issues
   - Channels, items, and content display full-screen using `.push` navigation
   - MediaCoordinator uses `.fullScreen` to prevent navigation stack corruption
   - Video player properly stops on dismiss (no background playback)

3. **Leaner Codebase**: Removed entire iOS build and code (28,370+ deletions)
   - tvOS-only focus reduces complexity
   - Faster build times and easier maintenance
   - Single target: `jellypig tvOS`

## Technical Changes

### Core Fixes
- **ItemLibraryViewModel.swift**: Implements proper channel API routing (`/Channels/{channelID}/Items`)
- **PagingLibraryView.swift**: Added `.channelFolderItem` support for grid view display
- **MainCoordinator.swift**: Restructured MediaCoordinator routing with `.fullScreen` navigation
- **ItemView.swift**: Removed `.channelFolderItem` handling (delegates to library view)

### Project Configuration
- **Bundle ID**: `org.ashik.jellypig`
- **Project Name**: jellypig (renamed from Swiftfin)
- **Targets**: tvOS only (iOS removed)
- **CI/CD**: Updated GitHub Actions workflows for jellypig tvOS builds
- **Dependencies**: Properly configured VLCKit (TVVLCKit.xcframework v3.5.0)

## Known Limitations

### Acceptable Trade-offs
- **Error Dismissal**: Errors in deeply nested views (e.g., failed episode playback) dismiss all the way to Media tab instead of one level back
  - This is a limitation of `.fullScreen` presentation architecture
  - Prevents worse issue of returning to Home screen

- **Video Player Back Button**: Slightly "buggy" behavior but functional
  - ESC key works properly (shows controls → confirm → exit)
  - Playback stops correctly on dismiss

## Development Environment

### Requirements
- **Platform**: macOS with Xcode 16+
- **Build Method**: Must use Xcode GUI (Command+B)
  - Command-line `xcodebuild` fails due to Swift macro issues in swift-case-paths dependency
  - All other operations (git, editing) work via command line
- **Simulator**: Any tvOS 16.0+ simulator or device

### Repository
- **Fork**: [ashikslab/jellypig](https://github.com/ashikslab/jellypig)
- **Upstream**: [jellyfin/swiftfin](https://github.com/jellyfin/swiftfin)
- **Plugin**: [ashikslab/Jellyfin.Xtream](https://github.com/ashikslab/Jellyfin.Xtream)

## Companion Plugin

jellypig works best with the reverted **Jellyfin.Xtream** plugin (v0.7.2.0001) which uses pure upstream logic:
- Repository: https://ashikslab.github.io/Jellyfin.Xtream/repository.json
- Download: https://github.com/ashikslab/Jellyfin.Xtream/releases/download/v0.7.2.0001/jellyfin-xtream-for-jellypig_0.7.2.1.zip

The plugin provides standard Jellyfin Channel API endpoints for Xtream content, and jellypig handles the display and navigation correctly.

## What's Next

### Short Term (Until Upstream Stabilizes)
- Bug fixes as discovered
- UI adjustments and polish
- Stay on Swiftfin 1.3 base

### Long Term
- **Major Intake**: When upstream Swiftfin releases their next stable major version, jellypig will merge those changes
- **iOS Support**: May consider re-adding iOS support with Xtream fixes as a separate project
- **Upstream Contributions**: Channel navigation fixes could potentially be contributed back to Swiftfin

## Credits

- **Original Project**: [Jellyfin Swiftfin](https://github.com/jellyfin/swiftfin) - MPL-2.0 License
- **Plugin**: [Kevinjil/Jellyfin.Xtream](https://github.com/Kevinjil/Jellyfin.Xtream) - GPL-3.0 License
- **jellypig Fork**: Personal modifications for Xtream content support and tvOS optimization

---

**This is an alpha release**: Suitable for personal use and testing. Report issues at https://github.com/ashikslab/jellypig/issues
