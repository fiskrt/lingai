import SwiftUI

struct ReadingPassageView: View {
    let passage: ReadingPassage
    @ObservedObject var readingManager: ReadingManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedAnswers: [Int] = []
    @State private var showingResults = false
    @State private var currentQuestionIndex = 0
    @State private var showingQuestions = false
    @State private var showingControls = false
    
    init(passage: ReadingPassage, readingManager: ReadingManager) {
        self.passage = passage
        self.readingManager = readingManager
        self._selectedAnswers = State(initialValue: Array(repeating: -1, count: passage.questions.count))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !showingQuestions {
                readingContentView
            } else if !showingResults {
                questionsView
            } else {
                resultsView
            }
        }
        .navigationTitle(passage.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .toolbar(showingControls ? .visible : .hidden, for: .tabBar)
        .ignoresSafeArea(showingControls ? [] : .all)
        .simultaneousGesture(
            DragGesture(minimumDistance: 50)
                .onChanged { value in
                    // Detect swipe from left edge
                    if value.startLocation.x < 150 && value.translation.width > 100 && abs(value.translation.height) < 100 {
                        showingControls = true
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
        .overlay(
            // Custom navigation bar overlay
            VStack {
                if showingControls {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text(passage.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Invisible spacer to center title
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .opacity(0)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
            }
            .animation(.easeInOut(duration: 0.3), value: showingControls)
        )
    }
    
    
    private var readingContentView: some View {
        ZStack {
            // Full screen reading content - static positioning
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(passage.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    Text(passage.content)
                        .font(.body)
                        .lineSpacing(6)
                        .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDisabled(false)
            .background(Color(.systemBackground))
            .overlay(
                // Status bar area overlay when in focused mode
                VStack {
                    if !showingControls {
                        LinearGradient(
                            colors: [Color(.systemBackground).opacity(0.9), Color(.systemBackground).opacity(0.6), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 50)
                        .transition(.opacity)
                    }
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.3), value: showingControls),
                alignment: .top
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingControls.toggle()
                }
            }
            
            // Bottom button with backdrop
            if showingControls {
                VStack {
                    Spacer()
                    
                    // Gradient backdrop to make button more visible
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 60)
                        
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .frame(height: 120)
                    }
                    .overlay(
                        VStack(spacing: 12) {
                            // Audio play button
                            if passage.audioFilePath != nil {
                                Button(action: {
                                    if readingManager.isPlayingAudio {
                                        readingManager.pauseAudio()
                                    } else {
                                        readingManager.playAudio(for: passage)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: readingManager.isPlayingAudio ? "pause.fill" : "play.fill")
                                        Text(readingManager.isPlayingAudio ? "Pause Audio" : "Play Audio")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button(action: {
                                showingQuestions = true
                                showingControls = false
                            }) {
                                Text("Start Questions")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.duoBlue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 10),
                        alignment: .bottom
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private var questionsView: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(passage.questions.count))
                .padding(.horizontal)
            
            Text("Question \(currentQuestionIndex + 1) of \(passage.questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(passage.questions[currentQuestionIndex].question)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(passage.questions[currentQuestionIndex].options.enumerated()), id: \.offset) { index, option in
                            OptionButton(
                                text: option,
                                isSelected: selectedAnswers[currentQuestionIndex] == index,
                                action: {
                                    selectedAnswers[currentQuestionIndex] = index
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            HStack {
                if currentQuestionIndex > 0 {
                    Button("Previous") {
                        currentQuestionIndex -= 1
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button(currentQuestionIndex == passage.questions.count - 1 ? "Finish" : "Next") {
                    if currentQuestionIndex == passage.questions.count - 1 {
                        finishQuiz()
                    } else {
                        currentQuestionIndex += 1
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAnswers[currentQuestionIndex] == -1)
            }
            .padding()
        }
    }
    
    private var resultsView: some View {
        let score = calculateScore()
        
        return VStack(spacing: 24) {
            Text("Quiz Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("\(score)%")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(score >= 70 ? .green : score >= 50 ? .orange : .red)
                
                Text("Score")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(passage.questions.enumerated()), id: \.offset) { index, question in
                        QuestionResultView(
                            question: question,
                            selectedAnswer: selectedAnswers[index],
                            questionNumber: index + 1
                        )
                    }
                }
                .padding()
            }
            
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
    
    private func finishQuiz() {
        readingManager.completeSession(for: passage.id, answers: selectedAnswers)
        showingResults = true
    }
    
    private func calculateScore() -> Int {
        var correct = 0
        for (index, answer) in selectedAnswers.enumerated() {
            if answer == passage.questions[index].correctAnswerIndex {
                correct += 1
            }
        }
        return Int((Double(correct) / Double(passage.questions.count)) * 100)
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .duoBlue : .gray)
            }
            .padding()
            .background(isSelected ? Color.duoBlue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.duoBlue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuestionResultView: View {
    let question: ComprehensionQuestion
    let selectedAnswer: Int
    let questionNumber: Int
    
    private var isCorrect: Bool {
        selectedAnswer == question.correctAnswerIndex
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Question \(questionNumber)")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            Text(question.question)
                .font(.body)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    HStack {
                        Text(option)
                            .font(.caption)
                        
                        Spacer()
                        
                        if index == question.correctAnswerIndex {
                            Text("Correct")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else if index == selectedAnswer && !isCorrect {
                            Text("Your Answer")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        index == question.correctAnswerIndex ? Color.green.opacity(0.1) :
                        index == selectedAnswer && !isCorrect ? Color.red.opacity(0.1) :
                        Color.clear
                    )
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}