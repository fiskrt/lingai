import SwiftUI

struct WordDetailView: View {
    let word: Word
    @Binding var isPresented: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header with close button
                HStack(alignment: .top) {
                    Text(word.german)
                        .font(.title2.bold())
                        .foregroundColor(.duoBlue)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.1, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                // Meaning Card
                InfoCard(
                    icon: "globe",
                    title: "Meaning",
                    content: word.english,
                    accentColor: .duoGreen,
                    showIcon: false
                )

                // Why this translation makes sense (Swedish)
                InfoCard(
                    icon: "text.quote",
                    title: "Varför",
                    content: word.whySwedish.isEmpty ? "Ingen förklaring tillganglig" : word.whySwedish,
                    accentColor: .duoBlue,
                    isEmpty: word.whySwedish.isEmpty,
                    showIcon: false
                )
                
                // Synonyms Card
                InfoCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Synonyms",
                    content: word.synonyms.isEmpty ? "No synonyms available" : word.synonyms,
                    accentColor: .duoOrange,
                    isEmpty: word.synonyms.isEmpty,
                    showIcon: false
                )
                
                // Etymology Card
                InfoCard(
                    icon: "book.closed",
                    title: "Etymology",
                    content: word.etymology.isEmpty ? "No etymology information available" : word.etymology,
                    accentColor: .duoPurple,
                    isEmpty: word.etymology.isEmpty,
                    showIcon: false
                )
                
                // Date Added Card
                InfoCard(
                    icon: "calendar",
                    title: "Added",
                    content: word.timestamp.formatted(.dateTime.weekday().day().month().year()),
                    accentColor: .duoBlue,
                    showIcon: false
                )
            }
            .padding(18)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 380)
        .frame(maxHeight: 520)
    }
}
