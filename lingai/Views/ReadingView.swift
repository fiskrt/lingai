import SwiftUI

struct ReadingView: View {
    @ObservedObject var wordManager: WordManager
    @StateObject private var readingManager = ReadingManager()
    @State private var showingPassageDetail = false
    @State private var showingCustomInstructions = false
    @State private var customInstructions = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Unified Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reading & Listening")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Practice comprehension with text and audio")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        generateButton
                    }
                    
                    if readingManager.isGenerating {
                        generateLoadingView
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Content Area
                if readingManager.readingPassages.isEmpty && !readingManager.isGenerating {
                    emptyStateView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    passageScrollView
                }
            }
            .navigationBarHidden(true)
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
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.duoBlue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image("mysymbol")
                        .font(.system(size: 50))
                        .foregroundColor(.duoBlue)
                }
                
                VStack(spacing: 12) {
                    Text("Start Your Comprehension Journey")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Create engaging reading passages with audio from your vocabulary words. Perfect for practicing both reading and listening comprehension!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var passageScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(readingManager.readingPassages) { passage in
                    NavigationLink(destination: ReadingPassageView(passage: passage, readingManager: readingManager)) {
                        EnhancedPassageRow(passage: passage)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    
    private var generateButton: some View {
        Button(action: {
            showingCustomInstructions = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                Text("Generate")
                    .font(.system(size: 15, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.duoBlue, Color.duoBlue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: Color.duoBlue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(wordManager.words.isEmpty)
        .opacity(wordManager.words.isEmpty ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: wordManager.words.isEmpty)
    }
    
    private var generateLoadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.9)
                .progressViewStyle(CircularProgressViewStyle(tint: .duoBlue))
            
            Text("Creating your comprehension exercise...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.duoBlue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct EnhancedPassageRow: View {
    let passage: ReadingPassage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title and audio indicator
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(passage.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label("\(passage.questions.count)", systemImage: "questionmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.duoBlue)
                        
                        Label("\(passage.vocabularyWords.count)", systemImage: "book.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if passage.audioFilePath != nil {
                            Label("Audio", systemImage: "headphones")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Preview text
            Text(String(passage.content.prefix(120)) + "...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .lineSpacing(2)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                )
        )
    }
}

struct PassageRowContent: View {
    let passage: ReadingPassage
    
    var body: some View {
        EnhancedPassageRow(passage: passage)
    }
}

extension View {
    func roundedCornerStyle() -> some View {
        self.cornerRadius(12)
    }
}