import SwiftUI

struct GrammarPracticeView: View {
    @ObservedObject var wordManager: WordManager
    @StateObject private var grammarManager = GrammarManager()
    
    @State private var selectedExerciseType: GrammarExercise.ExerciseType = .fillInBlank
    @State private var showingExerciseSelection = true
    @State private var selectedAnswer: String?
    @State private var showingAnswer = false
    @State private var answerSubmitted = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.duoOrange.opacity(0.1), Color.duoYellow.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if showingExerciseSelection {
                            exerciseSelectionView
                        } else if let session = grammarManager.currentSession {
                            if session.isCompleted {
                                SessionResultsCard(
                                    session: session,
                                    onRestart: {
                                        grammarManager.restartSession()
                                        resetExerciseState()
                                    },
                                    onNewSession: {
                                        grammarManager.endSession()
                                        showingExerciseSelection = true
                                    }
                                )
                                .padding(.horizontal)
                            } else {
                                exerciseSessionView(session: session)
                            }
                        }
                        
                        if grammarManager.isGenerating {
                            generatingView
                        }
                        
                        if let errorMessage = grammarManager.errorMessage {
                            errorView(message: errorMessage)
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Grammar Practice")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var exerciseSelectionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 60))
                    .foregroundColor(.duoOrange)
                
                Text("Choose Exercise Type")
                    .font(.title.bold())
                    .foregroundColor(.primaryText)
                
                Text("Practice German grammar with your vocabulary words")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(GrammarExercise.ExerciseType.allCases, id: \.self) { type in
                    ExerciseTypeCard(
                        exerciseType: type,
                        isSelected: selectedExerciseType == type
                    ) {
                        selectedExerciseType = type
                    }
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                Text("You have \(wordManager.words.count) vocabulary words")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                
                if wordManager.words.isEmpty {
                    Text("Add some words first to generate exercises!")
                        .font(.body)
                        .foregroundColor(.duoOrange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Button("Generate Exercises") {
                        Task {
                            await grammarManager.generateNewSession(
                                from: Array(wordManager.words.prefix(10)),
                                type: selectedExerciseType
                            )
                            if grammarManager.currentSession != nil {
                                showingExerciseSelection = false
                                resetExerciseState()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.duoBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                    .disabled(grammarManager.isGenerating)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func exerciseSessionView(session: GrammarSession) -> some View {
        VStack(spacing: 24) {
            ProgressBar(
                progress: session.progress,
                current: session.currentIndex + 1,
                total: session.exercises.count
            )
            .padding(.horizontal)
            
            if let exercise = session.currentExercise {
                ExerciseQuestionCard(
                    exercise: exercise,
                    selectedAnswer: selectedAnswer,
                    showCorrectAnswer: showingAnswer,
                    onAnswerSelect: { answer in
                        selectedAnswer = answer
                    }
                )
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    if !answerSubmitted && selectedAnswer != nil && !selectedAnswer!.isEmpty {
                        Button("Submit Answer") {
                            let isCorrect = grammarManager.submitAnswer(selectedAnswer ?? "")
                            showingAnswer = true
                            answerSubmitted = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.duoGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    
                    if showingAnswer {
                        HStack(spacing: 12) {
                            if session.hasPrevious {
                                Button("Previous") {
                                    _ = grammarManager.previousExercise()
                                    resetExerciseState()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.primaryText)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                            }
                            
                            Button("Regenerate") {
                                Task {
                                    await grammarManager.regenerateCurrentExercise(from: wordManager.words)
                                    resetExerciseState()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.duoYellow)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .fontWeight(.semibold)
                            .disabled(grammarManager.isGenerating)
                            
                            if session.hasNext {
                                Button("Next") {
                                    _ = grammarManager.nextExercise()
                                    resetExerciseState()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.duoBlue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                            } else {
                                Button("Finish") {
                                    _ = grammarManager.nextExercise()
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.duoGreen)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                            }
                        }
                    }
                    
                    Button("End Session") {
                        grammarManager.endSession()
                        showingExerciseSelection = true
                        resetExerciseState()
                    }
                    .foregroundColor(.duoRed)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var generatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Generating exercises...")
                .font(.headline)
                .foregroundColor(.primaryText)
        }
        .padding(32)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.duoRed)
            
            Text("Error")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Dismiss") {
                grammarManager.errorMessage = nil
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color.duoRed)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private func resetExerciseState() {
        selectedAnswer = nil
        showingAnswer = false
        answerSubmitted = false
    }
}