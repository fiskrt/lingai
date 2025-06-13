import SwiftUI

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
                            
                            // Flashcard with swipe gestures
                            FlashcardView(
                                word: practiceWords[currentWordIndex],
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
