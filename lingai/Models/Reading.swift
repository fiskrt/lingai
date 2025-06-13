import Foundation

struct ReadingPassage: Identifiable, Codable {
    let id = UUID()
    let title: String
    let content: String
    let questions: [ComprehensionQuestion]
    let vocabularyWords: [String]
    let timestamp: Date
    
    init(title: String, content: String, questions: [ComprehensionQuestion], vocabularyWords: [String], timestamp: Date = Date()) {
        self.title = title
        self.content = content
        self.questions = questions
        self.vocabularyWords = vocabularyWords
        self.timestamp = timestamp
    }
}

struct ComprehensionQuestion: Identifiable, Codable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctAnswerIndex: Int
    
    init(question: String, options: [String], correctAnswerIndex: Int) {
        self.question = question
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
    }
}

struct ReadingSession: Identifiable, Codable {
    let id = UUID()
    let passageId: UUID
    let answers: [Int]
    let score: Int
    let completedAt: Date
    
    init(passageId: UUID, answers: [Int], score: Int, completedAt: Date = Date()) {
        self.passageId = passageId
        self.answers = answers
        self.score = score
        self.completedAt = completedAt
    }
}