import Foundation

struct GrammarExercise: Identifiable, Codable {
    let id = UUID()
    let type: ExerciseType
    let question: String
    let correctAnswer: String
    let options: [String]?
    let explanation: String
    let difficulty: Difficulty
    let usedWords: [String]
    
    enum ExerciseType: String, CaseIterable, Codable {
        case fillInBlank = "fill_blank"
        case sentenceBuilding = "sentence_building"
        case caseSelection = "case_selection"
        case verbConjugation = "verb_conjugation"
        
        var displayName: String {
            switch self {
            case .fillInBlank: return "Fill in the Blank"
            case .sentenceBuilding: return "Sentence Building"
            case .caseSelection: return "Case Selection"
            case .verbConjugation: return "Verb Conjugation"
            }
        }
        
        var icon: String {
            switch self {
            case .fillInBlank: return "text.cursor"
            case .sentenceBuilding: return "textformat.abc"
            case .caseSelection: return "doc.text"
            case .verbConjugation: return "character.cursor.ibeam"
            }
        }
    }
    
    enum Difficulty: String, CaseIterable, Codable {
        case beginner, intermediate, advanced
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
}

struct GrammarSession: Identifiable, Codable {
    let id = UUID()
    var exercises: [GrammarExercise]
    var currentIndex: Int = 0
    var score: Int = 0
    var correctAnswers: Int = 0
    var startTime: Date = Date()
    var isCompleted: Bool = false
    
    var currentExercise: GrammarExercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }
    
    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentIndex) / Double(exercises.count)
    }
    
    var hasNext: Bool {
        return currentIndex < exercises.count - 1
    }
    
    var hasPrevious: Bool {
        return currentIndex > 0
    }
    
    mutating func nextExercise() -> Bool {
        if hasNext {
            currentIndex += 1
            return true
        } else {
            isCompleted = true
            return false
        }
    }
    
    mutating func previousExercise() -> Bool {
        if hasPrevious {
            currentIndex -= 1
            return true
        }
        return false
    }
    
    mutating func submitAnswer(_ answer: String) -> Bool {
        guard let current = currentExercise else { return false }
        let isCorrect = answer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == 
                       current.correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isCorrect {
            score += 100
            correctAnswers += 1
        }
        
        return isCorrect
    }
}