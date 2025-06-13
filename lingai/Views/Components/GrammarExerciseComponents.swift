import SwiftUI

struct ExerciseTypeCard: View {
    let exerciseType: GrammarExercise.ExerciseType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: exerciseType.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .duoBlue)
                
                Text(exerciseType.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.duoBlue : Color.cardBackground)
                    .shadow(
                        color: isSelected ? .duoBlue.opacity(0.3) : .black.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExerciseQuestionCard: View {
    let exercise: GrammarExercise
    let selectedAnswer: String?
    let showCorrectAnswer: Bool
    let onAnswerSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(exercise.type.displayName)
                        .font(.caption)
                        .foregroundColor(.duoBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.duoBlue.opacity(0.1))
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    Text(exercise.difficulty.displayName)
                        .font(.caption)
                        .foregroundColor(.duoOrange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.duoOrange.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Text(exercise.question)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
            }
            
            if exercise.type == .sentenceBuilding {
                SentenceBuildingInput(
                    correctAnswer: exercise.correctAnswer,
                    selectedAnswer: selectedAnswer,
                    showCorrectAnswer: showCorrectAnswer,
                    onAnswerChange: onAnswerSelect
                )
            } else {
                MultipleChoiceOptions(
                    options: exercise.options ?? [],
                    correctAnswer: exercise.correctAnswer,
                    selectedAnswer: selectedAnswer,
                    showCorrectAnswer: showCorrectAnswer,
                    onAnswerSelect: onAnswerSelect
                )
            }
            
            if showCorrectAnswer {
                ExplanationCard(explanation: exercise.explanation)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct MultipleChoiceOptions: View {
    let options: [String]
    let correctAnswer: String
    let selectedAnswer: String?
    let showCorrectAnswer: Bool
    let onAnswerSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                OptionButton(
                    text: option,
                    isSelected: selectedAnswer == option,
                    isCorrect: showCorrectAnswer && option == correctAnswer,
                    isWrong: showCorrectAnswer && selectedAnswer == option && option != correctAnswer,
                    isDisabled: showCorrectAnswer
                ) {
                    if !showCorrectAnswer {
                        onAnswerSelect(option)
                    }
                }
            }
        }
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var backgroundColor: Color {
        if isCorrect { return .duoGreen }
        if isWrong { return .duoRed }
        if isSelected { return .duoBlue }
        return .cardBackground
    }
    
    var borderColor: Color {
        if isCorrect { return .duoGreen }
        if isWrong { return .duoRed }
        if isSelected { return .duoBlue }
        return .gray.opacity(0.3)
    }
    
    var textColor: Color {
        if isCorrect || isWrong || isSelected { return .white }
        return .primaryText
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Spacer()
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

struct SentenceBuildingInput: View {
    let correctAnswer: String
    let selectedAnswer: String?
    let showCorrectAnswer: Bool
    let onAnswerChange: (String) -> Void
    
    @State private var userInput: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your answer:")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            TextField("Type your sentence here...", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(showCorrectAnswer)
                .onChange(of: userInput) { newValue in
                    onAnswerChange(newValue)
                }
            
            if showCorrectAnswer {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Correct answer:")
                        .font(.subheadline)
                        .foregroundColor(.duoGreen)
                    
                    Text(correctAnswer)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.duoGreen)
                        .padding(12)
                        .background(Color.duoGreen.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct ExplanationCard: View {
    let explanation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.duoYellow)
                
                Text("Explanation")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
            }
            
            Text(explanation)
                .font(.body)
                .foregroundColor(.secondaryText)
        }
        .padding(16)
        .background(Color.duoYellow.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProgressBar: View {
    let progress: Double
    let current: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Text("\(current)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.duoGreen)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

struct SessionResultsCard: View {
    let session: GrammarSession
    let onRestart: () -> Void
    let onNewSession: () -> Void
    
    var percentage: Int {
        guard !session.exercises.isEmpty else { return 0 }
        return Int((Double(session.correctAnswers) / Double(session.exercises.count)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: percentage >= 70 ? "star.fill" : "star")
                    .font(.system(size: 60))
                    .foregroundColor(percentage >= 70 ? .duoYellow : .gray)
                
                Text("Session Complete!")
                    .font(.title.bold())
                    .foregroundColor(.primaryText)
                
                Text("\(percentage)% Correct")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(percentage >= 70 ? .duoGreen : .duoOrange)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Correct Answers:")
                    Spacer()
                    Text("\(session.correctAnswers)/\(session.exercises.count)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Score:")
                    Spacer()
                    Text("\(session.score)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Time:")
                    Spacer()
                    Text(formatDuration(Date().timeIntervalSince(session.startTime)))
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                Button("Try Again", action: onRestart)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.duoBlue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                Button("New Session", action: onNewSession)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.duoGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}