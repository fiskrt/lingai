import SwiftUI

struct FlashcardView: View {
    let word: Word
    @Binding var showingAnswer: Bool
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    @State private var cardFlipped = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Main flashcard - now tappable with fixed height
            ZStack {
                // Background card that rotates with different colors
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: showingAnswer ? 
                                [Color.duoGreen.opacity(0.4), Color.duoGreen.opacity(0.2)] :
                                [Color.duoBlue.opacity(0.1), Color.duoPurple.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: showingAnswer ? .duoGreen.opacity(0.3) : .duoBlue.opacity(0.15), radius: 20, x: 0, y: 10)
                    .frame(height: 220)
                    .rotation3DEffect(
                        .degrees(cardFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cardFlipped)
                
                // Text content with fixed positioning - word only
                VStack {
                    Spacer()
                    
                    Text(showingAnswer ? word.english : word.german)
                        .font(.title.bold())
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(3)
                    
                    Spacer()
                }
                .padding(24)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showingAnswer.toggle()
                    cardFlipped.toggle()
                }
            }
            
            // Tap hint outside the card
            if !showingAnswer {
                Text("Tap to reveal")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .opacity(0.7)
            }
            
            // Answer buttons - more compact
            if showingAnswer {
                HStack(spacing: 12) {
                    Button(action: {
                        onIncorrect()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingAnswer = false
                            cardFlipped = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Incorrect")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.duoRed)
                        )
                    }
                    
                    Button(action: {
                        onCorrect()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingAnswer = false
                            cardFlipped = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Correct")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.duoGreen)
                        )
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showingAnswer)
            }
        }
        .padding(.horizontal, 4)
    }
}