# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PopLex is a SwiftUI iOS/macOS app that serves as a multilingual dictionary with AI-powered lookups, notebook saving, and flashcard-based study mode. It integrates with MiniMax API for definitions and image generation, and uses AVSpeechSynthesizer for local pronunciation playback.

## Build & Run

```bash
# Generate Xcode project (requires XcodeGen)
xcodegen generate

# Build for iOS simulator
xcodebuild -project PopLex.xcodeproj -scheme PopLex -configuration Debug -destination 'platform=iOS Simulator,name=iPhone' build

# Build for macOS
xcodebuild -project PopLex.xcodeproj -scheme PopLexMac -configuration Debug -destination 'platform=macOS' build
```

**Requirements:** XcodeGen must be installed (`brew install xcodegen`) before generating the project. Swift 6.0.

## Architecture

The app follows a simple layered architecture:

- **App Layer** (`PopLex/App/`) — `PopLexAppModel` is the central `@Observable` state holder managing all app state including lookup flow, notebook, MiniMax credentials, and tab navigation. `PlatformSupport.swift` provides iOS/macOS platform abstractions.
- **Features Layer** (`PopLex/Features/`) — Three tab views: `LookupTabView` (word lookup), `NotebookTabView` (saved entries + story mode), `StudyTabView` (flashcards). Each feature is self-contained with its own views.
- **Services Layer** (`PopLex/Services/`) — `DictionaryLookupService` (actor) handles word lookups via MiniMax API. `ImageGenerationService` (actor) generates artwork. `PronunciationService` (MainActor) uses AVSpeechSynthesizer. `MiniMaxCredentialStore` (actor) manages API key via keychain or env var. `NotebookStore` (actor) persists state to Application Support directory.
- **Models Layer** (`PopLex/Models/`) — `NotebookEntry`, `LanguageOption`, `ExampleLine` are the core data models. `AIModels.swift` contains API payload types (`LookupPayload`, `NotebookStoryPayload`).
- **Theme** (`PopLex/Theme/`) — `PopLexTheme` defines the color palette (pink/blue/orange on pastel gradients) and reusable view components like `PopLexSurface`, `PopLexBackdrop`, `ConceptStickerView`.

## Key Design Patterns

- **`@Observable` + `@Environment`** — `PopLexAppModel` is injected via `@Environment` and accessed throughout the app. All state mutation happens through this model.
- **Actors for isolation** — `DictionaryLookupService`, `ImageGenerationService`, `MiniMaxAPIClient`, `MiniMaxCredentialStore`, and `NotebookStore` are all actors to protect mutable state during async operations.
- **Platform abstraction** — `PlatformImage` typealias (`UIImage`/`NSImage`) and conditional `#if os(macOS)` view modifiers handle iOS/macOS differences.
- **Fallback-first** — Services degrade gracefully when MiniMax API key is not configured, showing preview content instead of errors.

## MiniMax Integration

API key resolution order: `MINIMAX_API_KEY` environment variable → keychain → not configured.

When not configured, the app enters "preview mode" with placeholder content. The `MiniMaxCredentialStore` actor manages this state and exposes it as `MiniMaxCredentialState`.

## Data Persistence

`NotebookStore` saves to Application Support directory:
- `snapshot.json` — `AppSnapshot` containing language preferences and all notebook entries
- `Images/` directory — Generated artwork stored as `{entryID}.png`

## Custom Fonts

App uses Avenir Next family: AvenirNext-Regular, AvenirNext-Medium, AvenirNext-DemiBold, AvenirNext-Bold.
