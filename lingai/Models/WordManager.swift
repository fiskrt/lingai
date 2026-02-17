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

    @discardableResult
    func addWordIfUnique(_ word: Word) -> Bool {
        let normalizedGerman = word.german.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedEnglish = word.english.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let exists = words.contains {
            $0.german.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedGerman &&
            $0.english.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedEnglish
        }

        if exists {
            return false
        }

        words.append(word)
        saveWords()
        return true
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

    func addWord(_ word: Word, toFolder folder: String) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        if !words[index].folders.contains(folder) {
            words[index].folders.append(folder)
            saveWords()
        }
    }

    func removeWord(_ word: Word, fromFolder folder: String) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index].folders.removeAll { $0 == folder }
        saveWords()
    }
    
    func getWordsForPeriod(days: Int) -> [Word] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return words.filter { $0.timestamp >= cutoffDate }
    }

    func getWords(inFolder folder: String?) -> [Word] {
        guard let folder = folder else { return words }
        return words.filter { $0.folders.contains(folder) }
    }

    func getWords(inCategory category: String?) -> [Word] {
        guard let category = category else { return words }
        return words.filter { $0.category == category }
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
