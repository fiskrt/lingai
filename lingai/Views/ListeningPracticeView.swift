import SwiftUI

struct ListeningPracticeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.duoPurple.opacity(0.1), Color.duoRed.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    Image(systemName: "headphones")
                        .font(.system(size: 80))
                        .foregroundColor(.duoPurple)
                    
                    VStack(spacing: 16) {
                        Text("Listening Practice")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primaryText)
                        
                        Text("Coming Soon!")
                            .font(.title2.bold())
                            .foregroundColor(.duoPurple)
                        
                        Text("Get ready for immersive listening exercises with native German speakers.")
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