import SwiftUI
import Foundation

// MARK: - Data Models
struct Word: Identifiable, Codable {
    let id = UUID()
    let german: String
    let english: String
    let timestamp: Date
    var isLearned: Bool = false
    
    init(german: String, english: String, timestamp: Date = Date()) {
        self.german = german
        self.english = english
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

// MARK: - Translation Service (Mock Implementation)
func translate(_ text: String, from sourceLanguage: String = "de", to targetLanguage: String = "en") -> String {
    // This is your perfect translation function
    // For demo purposes, I'll add some basic translations
    let translations = [
        "blumen": "flowers",
        "haus": "house",
        "katze": "cat",
        "hund": "dog",
        "wasser": "water",
        "brot": "bread",
        "auto": "car",
        "schule": "school"
    ]
    
    if sourceLanguage == "de" && targetLanguage == "en" {
        return translations[text.lowercased()] ?? "Translation for '\(text)'"
    } else if sourceLanguage == "en" && targetLanguage == "de" {
        let reverseDict = Dictionary(uniqueKeysWithValues: translations.map { ($1, $0) })
        return reverseDict[text.lowercased()] ?? "Übersetzung für '\(text)'"
    }
    
    return text
}

// MARK: - Word Input View
struct WordInputView: View {
    @ObservedObject var wordManager: WordManager
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New Words")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("German Word")
                        .font(.headline)
                    
                    TextField("Enter German word...", text: $inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .onChange(of: inputText) { _ in
                            translateWord()
                        }
                }
                
                if !translatedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("English Translation")
                            .font(.headline)
                        
                        Text(translatedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Button(action: saveWord) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Save Word")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(inputText.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(inputText.isEmpty)
                
                if showSuccessMessage {
                    Text("Word saved successfully!")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
                
                // Recent words section
                if !wordManager.words.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Recent Words")
                            .font(.headline)
                            .padding(.top)
                        
                        LazyVStack {
                            ForEach(Array(wordManager.words.suffix(5).reversed())) { word in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(word.german)
                                            .font(.headline)
                                        Text(word.english)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(word.timestamp.formatted(.dateTime.day().month().hour().minute()))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func translateWord() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            translatedText = ""
            return
        }
        
        isTranslating = true
        // Simulate slight delay for translation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            translatedText = translate(inputText.trimmingCharacters(in: .whitespacesAndNewlines))
            isTranslating = false
        }
    }
    
    private func saveWord() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        let newWord = Word(german: trimmedInput, english: translatedText)
        wordManager.addWord(newWord)
        
        inputText = ""
        translatedText = ""
        showSuccessMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
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
            VStack(spacing: 20) {
                Text("Vocabulary Practice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Period selector
                VStack {
                    Text("Practice words from the last:")
                        .font(.headline)
                    
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(periodOptions, id: \.self) { days in
                            Text("\(days) day\(days == 1 ? "" : "s")")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedPeriod) { _ in
                        setupPracticeSession()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                if practiceWords.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No words to practice")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Add some words in the Input tab first!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    // Score display
                    HStack {
                        Text("Score: \(sessionScore)/\(totalAnswered)")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("Card \(currentWordIndex + 1) of \(practiceWords.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Flashcard
                    FlashcardView(
                        word: practiceWords[currentWordIndex],
                        showingAnswer: $showingAnswer,
                        onCorrect: handleCorrect,
                        onIncorrect: handleIncorrect
                    )
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        Button("Previous") {
                            if currentWordIndex > 0 {
                                currentWordIndex -= 1
                                showingAnswer = false
                            }
                        }
                        .disabled(currentWordIndex == 0)
                        
                        Spacer()
                        
                        Button("Next") {
                            if currentWordIndex < practiceWords.count - 1 {
                                currentWordIndex += 1
                                showingAnswer = false
                            } else {
                                // Reset session
                                setupPracticeSession()
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .onAppear {
                setupPracticeSession()
            }
        }
    }
    
    private func setupPracticeSession() {
        practiceWords = wordManager.getWordsForPeriod(days: selectedPeriod).shuffled()
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

// MARK: - Flashcard View
struct FlashcardView: View {
    let word: Word
    @Binding var showingAnswer: Bool
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Card content
            VStack(spacing: 15) {
                Text(showingAnswer ? "English" : "German")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(showingAnswer ? word.english : word.german)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                
                if !showingAnswer {
                    Button("Show Answer") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAnswer = true
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            
            // Answer buttons
            if showingAnswer {
                HStack(spacing: 20) {
                    Button(action: {
                        onIncorrect()
                        showingAnswer = false
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Incorrect")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        onCorrect()
                        showingAnswer = false
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Correct")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Coming Soon Views
struct GrammarPracticeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Grammar Practice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming Soon!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("We're working on exciting grammar exercises to help you master German grammar rules.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct ListeningPracticeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "headphones")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
                
                Text("Listening Practice")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming Soon!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Get ready for immersive listening exercises with native German speakers.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
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
                    Image(systemName: "plus.circle")
                    Text("Add Words")
                }
            
            VocabularyPracticeView(wordManager: wordManager)
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Practice")
                }
            
            GrammarPracticeView()
                .tabItem {
                    Image(systemName: "text.book.closed")
                    Text("Grammar")
                }
            
            ListeningPracticeView()
                .tabItem {
                    Image(systemName: "headphones")
                    Text("Listening")
                }
        }
        .accentColor(.blue)
    }
}

// MARK: - App Entry Point
