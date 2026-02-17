# CLAUDE.md

This file provides guidance to coding agents working in this repository.

## Project Snapshot

LingAI is a SwiftUI iOS app for German learning with four tabs:

1. Add Words
2. Practice
3. Comprehend
4. Grammar

The app currently combines:

- AI-powered translation (Mistral)
- Vocabulary flashcard practice
- AI-generated reading passages with multiple-choice questions (Mistral)
- Passage audio generation and playback (OpenAI TTS)

Grammar is still a placeholder screen.

## Current Structure

```text
lingai/
├── App/
│   └── lingaiApp.swift
├── Models/
│   ├── Word.swift
│   ├── WordManager.swift
│   └── Reading.swift
├── Managers/
│   ├── llm.swift
│   └── ReadingManager.swift
├── Views/
│   ├── ContentView.swift
│   ├── WordInputView.swift
│   ├── VocabularyPracticeView.swift
│   ├── ReadingView.swift
│   ├── ReadingPassageView.swift
│   ├── ListeningPracticeView.swift          # Exists but is not wired into tabs
│   ├── GrammarPracticeView.swift
│   ├── SettingsView.swift
│   └── Components/
│       ├── EnDeToggle.swift
│       ├── WordRowView.swift
│       ├── WordDetailView.swift
│       ├── InfoCard.swift
│       ├── FlashcardView.swift
│       ├── PracticeComponents.swift
│       └── CustomInstructionsView.swift
├── Extensions/
│   └── Color+Extensions.swift
├── Assets.xcassets/
│   └── mysymbol.symbolset/                  # Custom tab icon used by Comprehend tab
└── Config.plist
```

## App Architecture

### Root Composition

- `ContentView` owns `@StateObject private var wordManager = WordManager()`.
- `wordManager` is injected into tabs requiring vocabulary data.
- `ReadingView` owns its own `@StateObject private var readingManager = ReadingManager()`.
- `SettingsView` is presented as a sheet from `ContentView`.

### Persistence

- `WordManager` persists `[Word]` to `UserDefaults` key: `SavedWords`.
- `ReadingManager` persists:
  - `[ReadingPassage]` to `readingPassages`
  - `[ReadingSession]` to `readingSessions`
- API keys are also persisted in `UserDefaults`:
  - `MistralAPIKey`
  - `OpenAIAPIKey`

### Data Models

- `Word`: German, English, timestamp, `isLearned`, `etymology`, `synonyms`.
- `ReadingPassage`: title, content, questions, vocabulary words, timestamp, optional audio file path.
- `ComprehensionQuestion`: question, options, correct answer index.
- `ReadingSession`: answers + score for completed quiz sessions.

## Implemented Features (Current Behavior)

### 1) Add Words (`WordInputView`)

- Input can be German or English (`EnDeToggle`).
- Saving triggers `translate_llm(...)` and stores:
  - source text + translated text
  - etymology
  - synonyms
- On API error, fallback word is saved with `"failed to trans"` placeholder.
- Shows up to 10 most recent words (`suffix(10).reversed()`).
- Swipe-to-delete in recent list.
- Tap row to show `WordDetailView` modal.
- Settings button is currently visible only when there is at least one saved word.

### 2) Practice (`VocabularyPracticeView`)

- Time-window filtering via `WordManager.getWordsForPeriod(days:)`.
- Period options: `1, 3, 7, 14, 30`.
- Flashcard reveal by tap (`FlashcardView`).
- Correct/Incorrect scoring with auto-advance.
- Marks words as learned when answered correct.
- Session restarts automatically after last card.

### 3) Comprehend (`ReadingView` + `ReadingPassageView`)

- Generate button opens `CustomInstructionsView` (optional prompt constraints).
- Passage generation uses all saved German words.
- Output includes title, ~300-word German text, and 4-5 multiple-choice questions.
- Background TTS generation starts immediately after passage creation.
- Passage list row shows question count, vocabulary count, and audio badge when available.
- Reading screen supports:
  - immersive text reading mode
  - audio controls (Play/Pause/Continue + Restart)
  - question flow with progress and results
  - stored quiz session completion
- Audio state is managed per selected passage; pause-on-exit behavior keeps resume position.

### 4) Grammar (`GrammarPracticeView`)

- Presentational "Coming Soon" screen only.

### 5) Listening (`ListeningPracticeView`)

- Also "Coming Soon" placeholder.
- Not currently reachable from main tab navigation.

## LLM + Audio Integration

All integration code is in `lingai/Managers/llm.swift`.

- Mistral chat endpoint: `https://api.mistral.ai/v1/chat/completions`
- Model: `mistral-large-latest`
- Uses JSON-response prompting and JSON parsing for:
  - `translate_llm(...)`
  - `generateReadingPassage(...)`

OpenAI TTS:

- Endpoint: `https://api.openai.com/v1/audio/speech`
- Model: `gpt-4o-mini-tts`
- Voice: `coral`
- Instruction prompt included for learner-friendly speech style.
- MP3 files are saved to app Documents directory as `<filename>.mp3`.

## API Key Configuration

`Config` in `llm.swift` resolves keys in this order:

1. In-memory cached values
2. `UserDefaults`
3. `Config.plist` in app bundle

`SettingsView` lets users set/update both keys at runtime and stores them in `UserDefaults`.

## Build & Runtime Facts

- Xcode project: `lingai.xcodeproj`
- Single app target: `lingai`
- No test target currently configured
- iOS deployment target: `18.4`
- Swift version setting: `5.0`
- Bundle identifier: `filipskogh.lingai`
- `Info.plist` is generated (`GENERATE_INFOPLIST_FILE = YES`)

Orientation behavior:

- `AppDelegate` enforces portrait via `supportedInterfaceOrientations`.
- Build settings still list landscape support keys in generated Info settings.
- Effective runtime behavior is portrait-only.

## Notes For Future Edits

- Keep `WordManager` and `ReadingManager` as the source of truth for persisted state.
- If you change `Word`, `ReadingPassage`, or `ReadingSession`, verify backward compatibility with existing `UserDefaults` payloads.
- `ReadingPassage.audioFilePath` stores a filename stem, not a full URL.
- `ReadingManager` currently appends passages in creation order and does not delete passages/sessions.
- `Config.plist` exists in repo but can be empty; runtime key entry via settings is supported and currently practical.
