import SwiftUI

struct GrammarPracticeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.duoOrange.opacity(0.1), Color.duoYellow.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 80))
                        .foregroundColor(.duoOrange)
                    
                    VStack(spacing: 16) {
                        Text("Grammar Practice")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primaryText)
                        
                        Text("Coming Soon!")
                            .font(.title2.bold())
                            .foregroundColor(.duoOrange)
                        
                        Text("We're working on exciting grammar exercises to help you master German grammar rules.")
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}