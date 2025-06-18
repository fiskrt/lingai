import SwiftUI

struct ReadingView: View {
    @ObservedObject var wordManager: WordManager
    @StateObject private var readingManager = ReadingManager()
    @State private var showingPassageDetail = false
    @State private var showingCustomInstructions = false
    @State private var customInstructions = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if readingManager.readingPassages.isEmpty && !readingManager.isGenerating {
                    emptyStateView
                } else {
                    passageListView
                }
            }
            .padding()
            .navigationTitle("Reading")
            .alert("Error", isPresented: .constant(readingManager.errorMessage != nil)) {
                Button("OK") {
                    readingManager.errorMessage = nil
                }
            } message: {
                Text(readingManager.errorMessage ?? "")
            }
            .sheet(isPresented: $showingCustomInstructions) {
                CustomInstructionsView(
                    customInstructions: $customInstructions,
                    isPresented: $showingCustomInstructions,
                    onGenerate: {
                        Task {
                            await readingManager.createReadingPassage(from: wordManager.words, customInstructions: customInstructions)
                        }
                    }
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(.duoBlue)
            
            Text("No Reading Passages")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Generate your first reading comprehension exercise using your vocabulary words!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            generateButton
        }
    }
    
    private var passageListView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Reading Passages")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                generateButton
            }
            
            if readingManager.isGenerating {
                generateLoadingView
            }
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(readingManager.readingPassages) { passage in
                        NavigationLink(destination: ReadingPassageView(passage: passage, readingManager: readingManager)) {
                            PassageRowContent(passage: passage)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var generateButton: some View {
        Button(action: {
            showingCustomInstructions = true
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.duoBlue)
            .foregroundColor(.white)
            .roundedCornerStyle()
        }
        .disabled(wordManager.words.isEmpty)
    }
    
    private var generateLoadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Generating reading passage...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .roundedCornerStyle()
    }
}

struct PassageRowContent: View {
    let passage: ReadingPassage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                Text(passage.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(passage.questions.count) questions • \(passage.vocabularyWords.count) vocabulary words")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(passage.content.prefix(100)) + "...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .roundedCornerStyle()
    }
}

extension View {
    func roundedCornerStyle() -> some View {
        self.cornerRadius(12)
    }
}