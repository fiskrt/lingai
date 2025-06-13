import SwiftUI

struct WordDetailView: View {
    let word: Word
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with close button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.german)
                        .font(.title.bold())
                        .foregroundColor(.duoBlue)
                    
                    Text("Word Details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.9)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            
            VStack(spacing: 16) {
                // Meaning Card
                InfoCard(
                    icon: "globe",
                    title: "Meaning",
                    content: word.english,
                    accentColor: .duoGreen
                )
                
                // Synonyms Card
                InfoCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Synonyms",
                    content: word.synonyms.isEmpty ? "No synonyms available" : word.synonyms,
                    accentColor: .duoOrange,
                    isEmpty: word.synonyms.isEmpty
                )
                
                // Etymology Card
                InfoCard(
                    icon: "book.closed",
                    title: "Etymology",
                    content: word.etymology.isEmpty ? "No etymology information available" : word.etymology,
                    accentColor: .duoPurple,
                    isEmpty: word.etymology.isEmpty
                )
                
                // Date Added Card
                InfoCard(
                    icon: "calendar",
                    title: "Added",
                    content: word.timestamp.formatted(.dateTime.weekday().day().month().year()),
                    accentColor: .duoBlue
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 380)
    }
}
