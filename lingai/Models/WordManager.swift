import Foundation

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