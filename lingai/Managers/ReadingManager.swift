import Foundation

class ReadingManager: ObservableObject {
    @Published var readingPassages: [ReadingPassage] = []
    @Published var completedSessions: [ReadingSession] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let passagesKey = "readingPassages"
    private let sessionsKey = "readingSessions"
    
    init() {
        loadPassages()
        loadSessions()
    }
    
    func createReadingPassage(from words: [Word]) async {
        DispatchQueue.main.async {
            self.isGenerating = true
            self.errorMessage = nil
        }
        
        let vocabularyWords = words.map { $0.german }
        guard !vocabularyWords.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "No vocabulary words available"
                self.isGenerating = false
            }
            return
        }
        
        do {
            let llmPassage = try await generateReadingPassage(vocabularyWords: vocabularyWords)
            
            let questions = llmPassage.questions.map { llmQuestion in
                ComprehensionQuestion(
                    question: llmQuestion.question,
                    options: llmQuestion.options,
                    correctAnswerIndex: llmQuestion.correct_answer
                )
            }
            
            let passage = ReadingPassage(
                title: llmPassage.title,
                content: llmPassage.content,
                questions: questions,
                vocabularyWords: vocabularyWords
            )
            
            DispatchQueue.main.async {
                self.readingPassages.append(passage)
                self.savePassages()
                self.isGenerating = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to generate reading passage: \(error.localizedDescription)"
                self.isGenerating = false
            }
        }
    }
    
    func completeSession(for passageId: UUID, answers: [Int]) {
        guard let passage = readingPassages.first(where: { $0.id == passageId }) else { return }
        
        let score = calculateScore(answers: answers, questions: passage.questions)
        let session = ReadingSession(passageId: passageId, answers: answers, score: score)
        
        completedSessions.append(session)
        saveSessions()
    }
    
    private func calculateScore(answers: [Int], questions: [ComprehensionQuestion]) -> Int {
        var correct = 0
        for (index, answer) in answers.enumerated() {
            if index < questions.count && answer == questions[index].correctAnswerIndex {
                correct += 1
            }
        }
        return Int((Double(correct) / Double(questions.count)) * 100)
    }
    
    private func loadPassages() {
        if let data = userDefaults.data(forKey: passagesKey),
           let passages = try? JSONDecoder().decode([ReadingPassage].self, from: data) {
            self.readingPassages = passages
        }
    }
    
    private func savePassages() {
        if let data = try? JSONEncoder().encode(readingPassages) {
            userDefaults.set(data, forKey: passagesKey)
        }
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let sessions = try? JSONDecoder().decode([ReadingSession].self, from: data) {
            self.completedSessions = sessions
        }
    }
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(completedSessions) {
            userDefaults.set(data, forKey: sessionsKey)
        }
    }
}