import SwiftUI

private enum PracticeDeckKind: Hashable {
    case myWords
    case recent(days: Int)
    case hardWords
    case storyCards
    case custom(id: String)
}

private struct PracticeDeckOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let count: Int
    let kind: PracticeDeckKind
}

struct VocabularyPracticeView: View {
    @ObservedObject var wordManager: WordManager
    @State private var activeDeckKind: PracticeDeckKind?
    @State private var activeDeckTitle = ""
    @State private var currentWordIndex = 0
    @State private var showingAnswer = false
    @State private var practiceWords: [Word] = []
    @State private var sessionScore = 0
    @State private var totalAnswered = 0
    @State private var showingCreateDeck = false

    private var userWords: [Word] {
        wordManager.getWords(inCategory: "user")
    }

    private var deckOptions: [PracticeDeckOption] {
        let recent3 = wordsFromLast(days: 3)
        let recent30 = wordsFromLast(days: 30)
        let hardWords = userWords.filter { $0.folders.contains("hard") }
        let storyCards = wordManager.getWords(inCategory: "story_flashcards")
        let customDecks = wordManager.customDecks.enumerated().map { index, deck in
            PracticeDeckOption(
                id: deck.id,
                title: deck.title,
                subtitle: "\(wordManager.getWords(inFolder: deck.folderKey).count) cards",
                systemImage: "sparkles",
                color: customDeckColor(index),
                count: wordManager.getWords(inFolder: deck.folderKey).count,
                kind: .custom(id: deck.id)
            )
        }

        return [
            PracticeDeckOption(
                id: "my_words",
                title: "My Words",
                subtitle: "\(userWords.count) cards",
                systemImage: "book.closed.fill",
                color: .duoBlue,
                count: userWords.count,
                kind: .myWords
            ),
            PracticeDeckOption(
                id: "last_3_days",
                title: "Last 3 Days",
                subtitle: "\(recent3.count) cards",
                systemImage: "calendar.badge.clock",
                color: .duoGreen,
                count: recent3.count,
                kind: .recent(days: 3)
            ),
            PracticeDeckOption(
                id: "last_30_days",
                title: "Last 30 Days",
                subtitle: "\(recent30.count) cards",
                systemImage: "calendar",
                color: .duoOrange,
                count: recent30.count,
                kind: .recent(days: 30)
            ),
            PracticeDeckOption(
                id: "hard_words",
                title: "Hard Words",
                subtitle: "\(hardWords.count) cards",
                systemImage: "bolt.heart.fill",
                color: .duoRed,
                count: hardWords.count,
                kind: .hardWords
            ),
            PracticeDeckOption(
                id: "story_cards",
                title: "Story Cards",
                subtitle: "\(storyCards.count) cards",
                systemImage: "text.book.closed.fill",
                color: .duoPurple,
                count: storyCards.count,
                kind: .storyCards
            )
        ] + customDecks
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                deckBackground

                if activeDeckKind == nil {
                    deckSelectionView
                } else {
                    practiceSessionView
                }

                if activeDeckKind == nil {
                    createDeckButton
                        .padding(.trailing, 22)
                        .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateDeck) {
                CreateFlashcardDeckSheet(wordManager: wordManager) { deck in
                    startPractice(
                        deck: PracticeDeckOption(
                            id: deck.id,
                            title: deck.title,
                            subtitle: "\(wordManager.getWords(inFolder: deck.folderKey).count) cards",
                            systemImage: "sparkles",
                            color: .duoPurple,
                            count: wordManager.getWords(inFolder: deck.folderKey).count,
                            kind: .custom(id: deck.id)
                        )
                    )
                }
            }
        }
    }

    private var deckBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.duoBlue.opacity(0.12),
                    Color.duoGreen.opacity(0.08),
                    Color.duoOrange.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.duoBlue.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 6)
                .offset(x: -150, y: -260)

            Circle()
                .fill(Color.duoOrange.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 8)
                .offset(x: 160, y: 260)
        }
    }

    private var deckSelectionView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Flashcard Decks")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primaryText)

                Text("Pick a bubble to start. Add a generated deck with the plus button.")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
            .padding(.top, 18)
            .padding(.horizontal, 22)

            DeckCanvasView(decks: deckOptions, onSelect: startPractice)
        }
    }

    private var practiceSessionView: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: returnToDecks) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Decks")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.duoBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.cardBackground.opacity(0.9)))
                }

                Spacer()

                Text(activeDeckTitle)
                    .font(.headline.bold())
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
            }
            .padding(.top, 18)

            if practiceWords.isEmpty {
                emptyPracticeState
            } else {
                VStack(spacing: 16) {
                    HStack {
                        ProgressCard(
                            title: "Score",
                            value: "\(sessionScore)/\(totalAnswered)",
                            color: .duoGreen
                        )

                        Spacer()

                        ProgressCard(
                            title: "Progress",
                            value: "\(currentWordIndex + 1)/\(practiceWords.count)",
                            color: .duoBlue
                        )
                    }

                    FlashcardView(
                        word: practiceWords[currentWordIndex],
                        positionText: "\(currentWordIndex + 1) of \(practiceWords.count)",
                        showingAnswer: $showingAnswer,
                        onCorrect: handleCorrect,
                        onIncorrect: handleIncorrect
                    )
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let swipeThreshold: CGFloat = 50

                                if value.translation.width > swipeThreshold {
                                    if currentWordIndex > 0 {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentWordIndex -= 1
                                            showingAnswer = false
                                        }
                                    }
                                } else if value.translation.width < -swipeThreshold {
                                    advanceOrRestart()
                                }
                            }
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var emptyPracticeState: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 52, weight: .semibold))
                .foregroundColor(.duoBlue.opacity(0.7))

            Text("No cards in this deck")
                .font(.title2.bold())
                .foregroundColor(.primaryText)

            Text("Choose another deck or create a generated deck from a prompt.")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)

            Button(action: returnToDecks) {
                Text("Back to Decks")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.duoBlue))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var createDeckButton: some View {
        Button {
            showingCreateDeck = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(LinearGradient(colors: [.duoOrange, .duoPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: .duoPurple.opacity(0.28), radius: 16, x: 0, y: 8)
                )
        }
        .accessibilityLabel("Create flashcard deck")
    }

    private func startPractice(deck: PracticeDeckOption) {
        activeDeckKind = deck.kind
        activeDeckTitle = deck.title
        practiceWords = words(for: deck.kind).shuffled()
        currentWordIndex = 0
        showingAnswer = false
        sessionScore = 0
        totalAnswered = 0
    }

    private func returnToDecks() {
        withAnimation(.easeInOut(duration: 0.25)) {
            activeDeckKind = nil
            activeDeckTitle = ""
            practiceWords = []
            currentWordIndex = 0
            showingAnswer = false
            sessionScore = 0
            totalAnswered = 0
        }
    }

    private func words(for deckKind: PracticeDeckKind) -> [Word] {
        switch deckKind {
        case .myWords:
            return userWords
        case .recent(let days):
            return wordsFromLast(days: days)
        case .hardWords:
            return userWords.filter { $0.folders.contains("hard") }
        case .storyCards:
            return wordManager.getWords(inCategory: "story_flashcards")
        case .custom(let id):
            guard let deck = wordManager.customDecks.first(where: { $0.id == id }) else { return [] }
            return wordManager.getWords(inFolder: deck.folderKey)
        }
    }

    private func wordsFromLast(days: Int) -> [Word] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return userWords.filter { $0.timestamp >= cutoffDate }
    }

    private func customDeckColor(_ index: Int) -> Color {
        let colors: [Color] = [.duoPurple, .duoRed, .duoYellow, .duoBlue, .duoGreen, .duoOrange]
        return colors[index % colors.count]
    }

    private func handleCorrect() {
        sessionScore += 1
        totalAnswered += 1
        wordManager.markAsLearned(practiceWords[currentWordIndex])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            advanceOrRestart()
        }
    }

    private func handleIncorrect() {
        totalAnswered += 1
        wordManager.addWord(practiceWords[currentWordIndex], toFolder: "hard")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            advanceOrRestart()
        }
    }

    private func advanceOrRestart() {
        if currentWordIndex < practiceWords.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentWordIndex += 1
                showingAnswer = false
            }
        } else if let activeDeckKind {
            practiceWords = words(for: activeDeckKind).shuffled()
            currentWordIndex = 0
            showingAnswer = false
        }
    }
}

private struct DeckCanvasView: View {
    let decks: [PracticeDeckOption]
    let onSelect: (PracticeDeckOption) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 128, maximum: 170), spacing: 18)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(decks) { deck in
                    DeckBubble(deck: deck) {
                        onSelect(deck)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 110)
        }
    }
}

private struct DeckBubble: View {
    let deck: PracticeDeckOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [deck.color.opacity(0.92), deck.color.opacity(0.58)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.42), lineWidth: 2)
                    )
                    .shadow(color: deck.color.opacity(0.28), radius: 18, x: 0, y: 10)

                VStack(spacing: 8) {
                    Image(systemName: deck.systemImage)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))

                    Text(deck.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    Text(deck.subtitle)
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.82))
                }
                .padding(18)
            }
            .frame(width: 142, height: 142)
            .opacity(deck.count == 0 ? 0.58 : 1)
        }
        .buttonStyle(.plain)
    }
}

private struct CreateFlashcardDeckSheet: View {
    @ObservedObject var wordManager: WordManager
    let onCreated: (CustomFlashcardDeck) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var prompt = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Generate a Deck")
                        .font(.title.bold())
                        .foregroundColor(.primaryText)

                    Text("Describe the deck you want, for example: “list of 30 kitchen items”.")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }

                TextEditor(text: $prompt)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.duoBlue.opacity(0.18), lineWidth: 1)
                    )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.duoRed)
                }

                Button(action: createDeck) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }

                        Text(isGenerating ? "Creating Deck..." : "Create 30 Cards")
                            .font(.headline.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canCreate ? Color.duoBlue : Color.gray.opacity(0.45))
                    )
                }
                .disabled(!canCreate)

                Spacer()
            }
            .padding(22)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }
            }
        }
    }

    private var canCreate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    private func createDeck() {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let cards = try await generatePromptFlashcardDeck(prompt: trimmedPrompt, count: 30)
                let deck = await MainActor.run {
                    wordManager.createCustomDeck(
                        title: deckTitle(from: trimmedPrompt),
                        prompt: trimmedPrompt,
                        cards: cards
                    )
                }

                await MainActor.run {
                    isGenerating = false
                    onCreated(deck)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func deckTitle(from prompt: String) -> String {
        let ignoredWords: Set<String> = ["a", "an", "the", "of", "for", "list", "make", "create", "deck", "flashcard", "flashcards", "words", "word", "items", "item", "30"]
        let words = prompt
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !ignoredWords.contains($0) && Int($0) == nil }

        let titleWords = Array(words.prefix(3))
        guard !titleWords.isEmpty else { return "Custom Deck" }
        return titleWords.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }
}
