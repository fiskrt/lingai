import SwiftUI

private struct PracticePeriodOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let days: Int?
}

private struct PracticeFolderOption: Identifiable, Hashable {
    let id: String
    let title: String
    let folderKey: String?
}

struct VocabularyPracticeView: View {
    @ObservedObject var wordManager: WordManager
    @State private var selectedPeriodDays: Int? = 7
    @State private var selectedFolderKey: String? = nil
    @State private var currentWordIndex = 0
    @State private var showingAnswer = false
    @State private var practiceWords: [Word] = []
    @State private var sessionScore = 0
    @State private var totalAnswered = 0
    @State private var showPeriodSelector = true
    
    private let periodOptions: [PracticePeriodOption] = [
        PracticePeriodOption(id: "all", title: "All", subtitle: "cards", days: nil),
        PracticePeriodOption(id: "1", title: "1", subtitle: "day", days: 1),
        PracticePeriodOption(id: "3", title: "3", subtitle: "days", days: 3),
        PracticePeriodOption(id: "7", title: "7", subtitle: "days", days: 7),
        PracticePeriodOption(id: "14", title: "14", subtitle: "days", days: 14),
        PracticePeriodOption(id: "30", title: "30", subtitle: "days", days: 30)
    ]
    private let folderOptions: [PracticeFolderOption] = [
        PracticeFolderOption(id: "all_words", title: "All Words", folderKey: nil),
        PracticeFolderOption(id: "hard_words", title: "Hard Words", folderKey: "hard")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.duoPurple.opacity(0.1), Color.duoBlue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header - only show when no practice words or when selector is shown
                    if practiceWords.isEmpty || showPeriodSelector {
                        VStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 32))
                                .foregroundColor(.duoPurple)
                            
                            Text("Practice Time!")
                                .font(.title.bold())
                                .foregroundColor(.primaryText)
                            
                            Text("Test your knowledge")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.top, 12)
                    }
                    
                    // Period selector - collapsible
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ForEach(folderOptions) { option in
                                Button(action: {
                                    selectedFolderKey = option.folderKey
                                    if option.folderKey == "hard" {
                                        selectedPeriodDays = nil
                                    }
                                    setupPracticeSession()
                                }) {
                                    Text(option.title)
                                        .font(.caption.bold())
                                        .foregroundColor(selectedFolderKey == option.folderKey ? .white : .duoBlue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    selectedFolderKey == option.folderKey
                                                        ? LinearGradient(colors: [.duoBlue, .duoPurple], startPoint: .leading, endPoint: .trailing)
                                                        : LinearGradient(colors: [Color.duoBlue.opacity(0.12)], startPoint: .leading, endPoint: .trailing)
                                                )
                                        )
                                }
                            }
                        }

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showPeriodSelector.toggle()
                            }
                        }) {
                            HStack {
                                Text(practiceWords.isEmpty ? "Choose practice range:" : "Range: \(selectedFolderLabel) • \(selectedPeriodLabel)")
                                    .font(.subheadline)
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                    .rotationEffect(.degrees(showPeriodSelector ? 0 : -90))
                                    .animation(.easeInOut(duration: 0.2), value: showPeriodSelector)
                            }
                        }
                        
                        if showPeriodSelector {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(periodOptions) { option in
                                        PeriodButton(
                                            title: option.title,
                                            subtitle: option.subtitle,
                                            isSelected: selectedPeriodDays == option.days
                                        ) {
                                            selectedPeriodDays = option.days
                                            setupPracticeSession()
                                            
                                            // Auto-collapse after selection if we have words
                                            if !practiceWords.isEmpty {
                                                withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
                                                    showPeriodSelector = false
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .shadow(color: .duoPurple.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    
                    if practiceWords.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.duoPurple.opacity(0.6))
                            
                            Text("No words to practice")
                                .font(.title2.bold())
                                .foregroundColor(.primaryText)
                            
                            Text(selectedFolderKey == "hard" ? "No hard words yet. Missed cards will be collected here." : "Add some words in the Add tab first!")
                                .font(.body)
                                .foregroundColor(.secondaryText)
                            
                            VStack(spacing: 4) {
                                Text("Available words: \(wordManager.words.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                
                                Text("Words in selection: \(availableWordsForSelection().count)")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Practice session
                        VStack(spacing: 16) {
                            // Progress and score
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
                            
                            // Flashcard with swipe gestures
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
                                            // Swipe right - go to previous card
                                            if currentWordIndex > 0 {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    currentWordIndex -= 1
                                                    showingAnswer = false
                                                }
                                            }
                                        } else if value.translation.width < -swipeThreshold {
                                            // Swipe left - go to next card
                                            if currentWordIndex < practiceWords.count - 1 {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    currentWordIndex += 1
                                                    showingAnswer = false
                                                }
                                            } else {
                                                // At the end, restart session
                                                setupPracticeSession()
                                            }
                                        }
                                    }
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
            .onAppear {
                setupPracticeSession()
            }
        }
    }
    
    private var selectedPeriodLabel: String {
        if let days = selectedPeriodDays {
            return "\(days) day\(days == 1 ? "" : "s")"
        }
        return "All cards"
    }

    private var selectedFolderLabel: String {
        selectedFolderKey == "hard" ? "Hard Words" : "All Words"
    }

    private func availableWordsForSelection() -> [Word] {
        let baseWords = wordManager.getWords(inFolder: selectedFolderKey)
        if let days = selectedPeriodDays {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            return baseWords.filter { $0.timestamp >= cutoffDate }
        }
        return baseWords
    }

    private func setupPracticeSession() {
        let availableWords = availableWordsForSelection()
        practiceWords = availableWords.shuffled()
        currentWordIndex = 0
        showingAnswer = false
        sessionScore = 0
        totalAnswered = 0
        
        // Auto-collapse selector when practice starts with words
        if !practiceWords.isEmpty {
            withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                showPeriodSelector = false
            }
        }
    }
    
    private func handleCorrect() {
        sessionScore += 1
        totalAnswered += 1
        wordManager.markAsLearned(practiceWords[currentWordIndex])
        
        // Auto-advance to next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if currentWordIndex < practiceWords.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentWordIndex += 1
                    showingAnswer = false
                }
            } else {
                // At the end, restart session
                setupPracticeSession()
            }
        }
    }
    
    private func handleIncorrect() {
        totalAnswered += 1
        wordManager.addWord(practiceWords[currentWordIndex], toFolder: "hard")
        
        // Auto-advance to next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if currentWordIndex < practiceWords.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentWordIndex += 1
                    showingAnswer = false
                }
            } else {
                // At the end, restart session
                setupPracticeSession()
            }
        }
    }
}
