import Foundation

class GrammarManager: ObservableObject {
    @Published var currentSession: GrammarSession?
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    func generateNewSession(from words: [Word], type: GrammarExercise.ExerciseType, count: Int = 5) async {
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        do {
            let wordStrings = words.map { "\($0.german) (\($0.english))" }
            let response = try await generate_grammar_exercises(
                words: wordStrings,
                exerciseType: type.rawValue,
                count: count
            )
            
            let exercises = response.exercises.compactMap { generated -> GrammarExercise? in
                guard let exerciseType = GrammarExercise.ExerciseType(rawValue: generated.type),
                      let difficulty = GrammarExercise.Difficulty(rawValue: generated.difficulty) else {
                    return nil
                }
                
                return GrammarExercise(
                    type: exerciseType,
                    question: generated.question,
                    correctAnswer: generated.correct_answer,
                    options: generated.options,
                    explanation: generated.explanation,
                    difficulty: difficulty,
                    usedWords: generated.used_words
                )
            }
            
            await MainActor.run {
                if !exercises.isEmpty {
                    self.currentSession = GrammarSession(exercises: exercises)
                } else {
                    self.errorMessage = "Failed to generate valid exercises. Please try again."
                }
                self.isGenerating = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate exercises: \(error.localizedDescription)"
                self.isGenerating = false
            }
        }
    }
    
    func nextExercise() -> Bool {
        guard var session = currentSession else { return false }
        let hasNext = session.nextExercise()
        currentSession = session
        return hasNext
    }
    
    func previousExercise() -> Bool {
        guard var session = currentSession else { return false }
        let hasPrev = session.previousExercise()
        currentSession = session
        return hasPrev
    }
    
    func submitAnswer(_ answer: String) -> Bool {
        guard var session = currentSession else { return false }
        let isCorrect = session.submitAnswer(answer)
        currentSession = session
        return isCorrect
    }
    
    func regenerateCurrentExercise(from words: [Word]) async {
        guard let session = currentSession,
              let currentExercise = session.currentExercise else { return }
        
        await MainActor.run {
            isGenerating = true
            errorMessage = nil
        }
        
        do {
            let wordStrings = words.map { "\($0.german) (\($0.english))" }
            let response = try await generate_grammar_exercises(
                words: wordStrings,
                exerciseType: currentExercise.type.rawValue,
                count: 1
            )
            
            if let generated = response.exercises.first,
               let exerciseType = GrammarExercise.ExerciseType(rawValue: generated.type),
               let difficulty = GrammarExercise.Difficulty(rawValue: generated.difficulty) {
                
                let newExercise = GrammarExercise(
                    type: exerciseType,
                    question: generated.question,
                    correctAnswer: generated.correct_answer,
                    options: generated.options,
                    explanation: generated.explanation,
                    difficulty: difficulty,
                    usedWords: generated.used_words
                )
                
                await MainActor.run {
                    var updatedSession = session
                    updatedSession.exercises[session.currentIndex] = newExercise
                    self.currentSession = updatedSession
                    self.isGenerating = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Failed to regenerate exercise. Please try again."
                    self.isGenerating = false
                }
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to regenerate exercise: \(error.localizedDescription)"
                self.isGenerating = false
            }
        }
    }
    
    func endSession() {
        currentSession = nil
        errorMessage = nil
    }
    
    func restartSession() {
        guard var session = currentSession else { return }
        session.currentIndex = 0
        session.score = 0
        session.correctAnswers = 0
        session.startTime = Date()
        session.isCompleted = false
        currentSession = session
    }
}