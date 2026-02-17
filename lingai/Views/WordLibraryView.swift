import SwiftUI

struct WordLibraryView: View {
    @ObservedObject var wordManager: WordManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredWords: [Word] {
        let sorted = wordManager.words.sorted { $0.timestamp > $1.timestamp }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return sorted }

        return sorted.filter { word in
            word.german.lowercased().contains(query) ||
            word.english.lowercased().contains(query) ||
            word.synonyms.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationView {
            List {
                if filteredWords.isEmpty {
                    VStack(spacing: 8) {
                        Text(searchText.isEmpty ? "No words saved yet" : "No matches found")
                            .font(.headline)
                            .foregroundColor(.secondaryText)

                        Text(searchText.isEmpty ? "Add words in the Add Words tab." : "Try a different search term.")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredWords) { word in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(word.german)
                                    .font(.headline)
                                    .foregroundColor(.primaryText)

                                Text(word.english)
                                    .font(.subheadline)
                                    .foregroundColor(.secondaryText)
                            }

                            Spacer()

                            if word.folders.contains("hard") {
                                Text("Hard")
                                    .font(.caption.bold())
                                    .foregroundColor(.duoRed)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.duoRed.opacity(0.12)))
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                wordManager.deleteWord(withId: word.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search words")
            .navigationTitle("Word Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
