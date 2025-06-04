import SwiftUI
import Foundation

// MARK: - Data Models
struct Word: Identifiable, Codable {
    let id = UUID()
    let german: String
    let english: String
    let timestamp: Date
    var isLearned: Bool = false
    var etymology: String = ""
    var synonyms: String = ""
    
    init(german: String, english: String, etymology: String = "", synonyms: String = "", timestamp: Date = Date()) {
        self.german = german
        self.english = english
        self.etymology = etymology
        self.synonyms = synonyms
        self.timestamp = timestamp
    }
}

// MARK: - Data Manager
class WordManager: ObservableObject {
    @Published var words: [Word] = []
    
    private let userDefaults = UserDefaults.standard
    private let wordsKey = "SavedWords"
    
    init() {
        loadWords()
    }
    
    func addWord(_ word: Word) {
        words.append(word)
        saveWords()
    }
    
    func deleteWord(at offsets: IndexSet) {
        words.remove(atOffsets: offsets)
        saveWords()
    }
    
    func deleteWord(withId id: UUID) {
        words.removeAll { $0.id == id }
        saveWords()
    }
    
    func markAsLearned(_ word: Word) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].isLearned.toggle()
            saveWords()
        }
    }
    
    func getWordsForPeriod(days: Int) -> [Word] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return words.filter { $0.timestamp >= cutoffDate }
    }
    
    private func saveWords() {
        if let encoded = try? JSONEncoder().encode(words) {
            userDefaults.set(encoded, forKey: wordsKey)
        }
    }
    
    private func loadWords() {
        if let data = userDefaults.data(forKey: wordsKey),
           let decoded = try? JSONDecoder().decode([Word].self, from: data) {
            words = decoded
        }
    }
}

// MARK: - Custom Colors and Styles
extension Color {
    static let duoGreen = Color(red: 0.33, green: 0.78, blue: 0.32)
    static let duoBlue = Color(red: 0.11, green: 0.63, blue: 0.94)
    static let duoOrange = Color(red: 1.0, green: 0.57, blue: 0.0)
    static let duoPurple = Color(red: 0.51, green: 0.29, blue: 0.96)
    static let duoYellow = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let duoRed = Color(red: 0.94, green: 0.33, blue: 0.31)
    
    // Adaptive colors for dark/light mode
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let surfaceBackground = Color(UIColor.systemBackground)
}

// MARK: - Word Detail View
struct WordDetailView: View {
    let word: Word
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with close button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.german)
                        .font(.title.bold())
                        .foregroundColor(.duoBlue)
                    
                    Text("Word Details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            
            VStack(spacing: 16) {
                // Meaning Card
                InfoCard(
                    icon: "globe",
                    title: "Meaning",
                    content: word.english,
                    accentColor: .duoGreen
                )
                
                // Synonyms Card
                InfoCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Synonyms",
                    content: word.synonyms.isEmpty ? "No synonyms available" : word.synonyms,
                    accentColor: .duoOrange,
                    isEmpty: word.synonyms.isEmpty
                )
                
                // Etymology Card
                InfoCard(
                    icon: "book.closed",
                    title: "Etymology",
                    content: word.etymology.isEmpty ? "No etymology information available" : word.etymology,
                    accentColor: .duoPurple,
                    isEmpty: word.etymology.isEmpty
                )
                
                // Date Added Card
                InfoCard(
                    icon: "calendar",
                    title: "Added",
                    content: word.timestamp.formatted(.dateTime.weekday().day().month().year()),
                    accentColor: .duoBlue
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 380)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color
    var isEmpty: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(content)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isEmpty ? .secondaryText : .primaryText)
                    .italic(isEmpty)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Toggle
struct EnDeToggle: View {
    @Binding var isGermanInput: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // English side
            Text("EN")
                .font(.caption.bold())
                .foregroundColor(isGermanInput ? .secondaryText : .white)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isGermanInput ? Color.clear : Color.duoBlue)
                        .scaleEffect(isGermanInput ? 0.8 : 1.0)
                )
            
            // German side
            Text("DE")
                .font(.caption.bold())
                .foregroundColor(isGermanInput ? .white : .secondaryText)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isGermanInput ? Color.duoGreen : Color.clear)
                        .scaleEffect(isGermanInput ? 1.0 : 0.8)
                )
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.gray.opacity(0.2))
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isGermanInput)
        .onTapGesture {
            withAnimation {
                isGermanInput.toggle()
            }
        }
    }
}

// MARK: - Word Input View
struct WordInputView: View {
    @ObservedObject var wordManager: WordManager
    @State private var inputText = ""
    @State private var isGermanInput = true
    @State private var selectedWord: Word?
    @State private var showingWordDetail = false
    @State private var showSuccessAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.duoBlue.opacity(0.1), Color.duoGreen.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(.duoBlue)
                        
                        Text("Add a Memory")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primaryText)
                        
                        Text("Expand your vocabulary")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.top, 20)
                    
                    // Input Card
                    VStack(spacing: 20) {
                        HStack(spacing: 16) {
                            // Input field
                            HStack {
                                Image(systemName: isGermanInput ? "flag.fill" : "flag")
                                    .foregroundColor(isGermanInput ? .duoGreen : .duoBlue)
                                    .font(.system(size: 16))
                                
                                TextField("Enter \(isGermanInput ? "German" : "English") word...", text: $inputText)
                                    .font(.body.weight(.medium))
                                    .autocorrectionDisabled(true)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.surfaceBackground)
                                    .stroke(Color.duoBlue.opacity(0.3), lineWidth: 2)
                            )
                            
                            // Language toggle
                            EnDeToggle(isGermanInput: $isGermanInput)
                        }
                        
                        // Save button
                        Button(action: saveWord) {
                            HStack(spacing: 8) {
                                Image(systemName: showSuccessAnimation ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text(showSuccessAnimation ? "Saved!" : "Save Word")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: inputText.isEmpty ? [.gray] : [.duoGreen, .duoBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .scaleEffect(showSuccessAnimation ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showSuccessAnimation)
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                            .shadow(color: .duoBlue.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    
                    // Recent Words Section
                    if !wordManager.words.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Recent Words")
                                        .font(.title2.bold())
                                        .foregroundColor(.primaryText)
                                    
                                    Text("Tap to view details • Swipe to delete")
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                                
                                Spacer()
                                
                                Text("\(wordManager.words.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.duoOrange)
                                    )
                            }
                            
                            List {
                                ForEach(Array(wordManager.words.suffix(10).reversed())) { word in
                                    WordRowView(word: word) {
                                        selectedWord = word
                                        showingWordDetail = true
                                    }
                                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                                .onDelete { indexSet in
                                    deleteRecentWords(at: indexSet)
                                }
                            }
                            .listStyle(PlainListStyle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.duoBlue.opacity(0.6))
                            
                            Text("No words yet!")
                                .font(.title2.bold())
                                .foregroundColor(.primaryText)
                            
                            Text("Add your first word above to get started")
                                .font(.body)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
            .overlay(
                Group {
                    if showingWordDetail, let selectedWord = selectedWord {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingWordDetail = false
                            }
                        
                        WordDetailView(word: selectedWord, isPresented: $showingWordDetail)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingWordDetail)
            )
        }
    }
    
    private func saveWord() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        // Show success animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showSuccessAnimation = true
        }
        
        // Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showSuccessAnimation = false
            }
        }
        
        // Add word logic using your translate_llm function
        Task {
            do {
                let result = try await translate_llm(phrase: trimmedInput, isGerman: isGermanInput)
                let newWord = Word(
                    german: isGermanInput ? trimmedInput : result.trans,
                    english: isGermanInput ? result.trans : trimmedInput,
                    etymology: result.etym
                )
                wordManager.addWord(newWord)
            } catch {
                print("Error calling translate_llm: \(error)")
                // Fallback on error
                let newWord = Word(
                    german: isGermanInput ? trimmedInput : "",
                    english: isGermanInput ? "" : trimmedInput
                )
                wordManager.addWord(newWord)
            }
        }
        inputText = ""
    }
    
    private func deleteRecentWords(at offsets: IndexSet) {
        let recentWords = Array(wordManager.words.suffix(10).reversed())
        let wordsToDelete = offsets.map { recentWords[$0] }
        
        for wordToDelete in wordsToDelete {
            wordManager.deleteWord(withId: wordToDelete.id)
        }
    }
}

// MARK: - Word Row View
struct WordRowView: View {
    let word: Word
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Flag icon
                Image(systemName: "flag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.duoGreen)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.duoGreen.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(word.german)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text(word.english)
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(word.timestamp.formatted(.dateTime.day().month()))
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    if word.isLearned {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.duoGreen)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surfaceBackground)
                    .shadow(color: .duoBlue.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vocabulary Practice View
struct VocabularyPracticeView: View {
    @ObservedObject var wordManager: WordManager
    @State private var selectedPeriod = 7
    @State private var currentWordIndex = 0
    @State private var showingAnswer = false
    @State private var practiceWords: [Word] = []
    @State private var sessionScore = 0
    @State private var totalAnswered = 0
    
    let periodOptions = [1, 3, 7, 14, 30]
    
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
                    // Header
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
                    
                    // Period selector
                    VStack(spacing: 12) {
                        Text("Practice words from the last:")
                            .font(.subheadline)
                            .foregroundColor(.primaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(periodOptions, id: \.self) { days in
                                    PeriodButton(
                                        days: days,
                                        isSelected: selectedPeriod == days
                                    ) {
                                        selectedPeriod = days
                                        setupPracticeSession()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
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
                            
                            Text("Add some words in the Add tab first!")
                                .font(.body)
                                .foregroundColor(.secondaryText)
                            
                            VStack(spacing: 4) {
                                Text("Available words: \(wordManager.words.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                
                                Text("Words in period: \(wordManager.getWordsForPeriod(days: selectedPeriod).count)")
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
                            
                            // Flashcard
                            FlashcardView(
                                word: practiceWords[currentWordIndex],
                                showingAnswer: $showingAnswer,
                                onCorrect: handleCorrect,
                                onIncorrect: handleIncorrect
                            )
                            
                            // Navigation buttons
                            HStack(spacing: 16) {
                                NavigationButton(
                                    title: "Previous",
                                    icon: "chevron.left",
                                    isDisabled: currentWordIndex == 0,
                                    color: .gray
                                ) {
                                    if currentWordIndex > 0 {
                                        currentWordIndex -= 1
                                        showingAnswer = false
                                    }
                                }
                                
                                Spacer()
                                
                                NavigationButton(
                                    title: currentWordIndex < practiceWords.count - 1 ? "Next" : "Restart",
                                    icon: "chevron.right",
                                    isDisabled: false,
                                    color: .duoBlue
                                ) {
                                    if currentWordIndex < practiceWords.count - 1 {
                                        currentWordIndex += 1
                                        showingAnswer = false
                                    } else {
                                        setupPracticeSession()
                                    }
                                }
                            }
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
    
    private func setupPracticeSession() {
        let availableWords = wordManager.getWordsForPeriod(days: selectedPeriod)
        practiceWords = availableWords.shuffled()
        currentWordIndex = 0
        showingAnswer = false
        sessionScore = 0
        totalAnswered = 0
    }
    
    private func handleCorrect() {
        sessionScore += 1
        totalAnswered += 1
        wordManager.markAsLearned(practiceWords[currentWordIndex])
    }
    
    private func handleIncorrect() {
        totalAnswered += 1
    }
}

// MARK: - Period Button
struct PeriodButton: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(days)")
                    .font(.headline.bold())
                    .foregroundColor(isSelected ? .white : .duoPurple)
                
                Text("day\(days == 1 ? "" : "s")")
                    .font(.caption2.bold())
                    .foregroundColor(isSelected ? .white : .duoPurple.opacity(0.7))
            }
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(
                        isSelected ?
                        LinearGradient(colors: [.duoPurple, .duoBlue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.duoPurple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondaryText)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Navigation Button
struct NavigationButton: View {
    let title: String
    let icon: String
    let isDisabled: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if icon == "chevron.left" {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                if icon == "chevron.right" {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(isDisabled ? .secondaryText : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? Color.gray.opacity(0.3) : color)
            )
        }
        .disabled(isDisabled)
    }
}

// MARK: - Enhanced Flashcard View
struct FlashcardView: View {
    let word: Word
    @Binding var showingAnswer: Bool
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    @State private var cardFlipped = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Main flashcard
            ZStack {
                // Background card that rotates
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.surfaceBackground, Color.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .duoBlue.opacity(0.15), radius: 20, x: 0, y: 10)
                    .frame(height: 220)
                    .rotation3DEffect(
                        .degrees(cardFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cardFlipped)
                
                // Text content on top (doesn't rotate)
                VStack(spacing: 16) {
                    Spacer()
                    
                    // Word display
                    Text(showingAnswer ? word.english : word.german)
                        .font(.title.bold())
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                    
                    Spacer()
                    
                    // Show answer button
                    if !showingAnswer {
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showingAnswer = true
                                cardFlipped = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "eye")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("Show Answer")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [.duoBlue, .duoPurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                    }
                }
                .padding(24)
            }
            
            // Answer buttons - more compact
            if showingAnswer {
                HStack(spacing: 12) {
                    Button(action: {
                        onIncorrect()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingAnswer = false
                            cardFlipped = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Incorrect")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.duoRed)
                        )
                    }
                    
                    Button(action: {
                        onCorrect()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingAnswer = false
                            cardFlipped = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Correct")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.duoGreen)
                        )
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showingAnswer)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Coming Soon Views
struct GrammarPracticeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.duoOrange.opacity(0.1), Color.duoYellow.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 80))
                        .foregroundColor(.duoOrange)
                    
                    VStack(spacing: 16) {
                        Text("Grammar Practice")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primaryText)
                        
                        Text("Coming Soon!")
                            .font(.title2.bold())
                            .foregroundColor(.duoOrange)
                        
                        Text("We're working on exciting grammar exercises to help you master German grammar rules.")
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ListeningPracticeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.duoPurple.opacity(0.1), Color.duoRed.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "headphones")
                        .font(.system(size: 80))
                        .foregroundColor(.duoPurple)
                    
                    VStack(spacing: 16) {
                        Text("Listening Practice")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primaryText)
                        
                        Text("Coming Soon!")
                            .font(.title2.bold())
                            .foregroundColor(.duoPurple)
                        
                        Text("Get ready for immersive listening exercises with native German speakers.")
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var wordManager = WordManager()
    
    var body: some View {
        TabView {
            WordInputView(wordManager: wordManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Words")
                }
            
            VocabularyPracticeView(wordManager: wordManager)
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Practice")
                }
            
            GrammarPracticeView()
                .tabItem {
                    Image(systemName: "text.book.closed.fill")
                    Text("Grammar")
                }
            
            ListeningPracticeView()
                .tabItem {
                    Image(systemName: "headphones")
                    Text("Listening")
                }
        }
        .accentColor(.duoBlue)
    }
}
