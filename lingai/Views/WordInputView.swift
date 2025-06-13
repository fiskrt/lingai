import SwiftUI

struct WordInputView: View {
    @ObservedObject var wordManager: WordManager
    @State private var inputText = ""
    @State private var isGermanInput = true
    @State private var selectedWord: Word?
    @State private var showingWordDetail = false
    @State private var showSuccessAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.duoBlue.opacity(0.1), Color.duoGreen.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Recent Words Section (now at top)
                    if !wordManager.words.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Recent Words")
                                        .font(.title2.bold())
                                        .foregroundColor(.primaryText)
                                    
                                    Text("Tap to view details • Swipe to delete")
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                                
                                Spacer()
                                
                                Text("\(wordManager.words.count)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.duoOrange)
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            List {
                                ForEach(Array(wordManager.words.suffix(10).reversed())) { word in
                                    WordRowView(word: word) {
                                        selectedWord = word
                                        showingWordDetail = true
                                    }
                                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                                .onDelete { indexSet in
                                    deleteRecentWords(at: indexSet)
                                }
                            }
                            .listStyle(PlainListStyle())
                            .padding(.horizontal, 20)
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.duoBlue.opacity(0.6))
                            
                            Text("No words yet!")
                                .font(.title2.bold())
                                .foregroundColor(.primaryText)
                            
                            Text("Add your first word below to get started")
                                .font(.body)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    Spacer()
                    
                    // Input Card (now at bottom)
                    VStack(spacing: 20) {
                        HStack(spacing: 16) {
                            // Input field
                            HStack {
                                Image(systemName: isGermanInput ? "flag.fill" : "flag")
                                    .foregroundColor(isGermanInput ? .duoGreen : .duoBlue)
                                    .font(.system(size: 16))
                                
                                TextField("Enter \(isGermanInput ? "German" : "English") word...", text: $inputText)
                                    .font(.body.weight(.medium))
                                    .autocorrectionDisabled(true)
                                    .onSubmit {
                                        if !inputText.isEmpty {
                                            saveWord()
                                        }
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.surfaceBackground)
                                    .stroke(Color.duoBlue.opacity(0.3), lineWidth: 2)
                            )
                            
                            // Language toggle
                            EnDeToggle(isGermanInput: $isGermanInput)
                        }
                        
                        // Save button
                        Button(action: saveWord) {
                            HStack(spacing: 8) {
                                Image(systemName: showSuccessAnimation ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text(showSuccessAnimation ? "Saved!" : "Save Word")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: inputText.isEmpty ? [.gray] : [.duoGreen, .duoBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .scaleEffect(showSuccessAnimation ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showSuccessAnimation)
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.cardBackground)
                            .shadow(color: .duoBlue.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                }
            }
            .navigationBarHidden(true)
            .overlay(
                Group {
                    if showingWordDetail, let selectedWord = selectedWord {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingWordDetail = false
                            }
                        
                        WordDetailView(word: selectedWord, isPresented: $showingWordDetail)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingWordDetail)
            )
        }
    }
    
    private func saveWord() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        // Show success animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showSuccessAnimation = true
        }
        
        // Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showSuccessAnimation = false
            }
        }
        
        // Add word logic using your translate_llm function
        Task {
            do {
                let result = try await translate_llm(phrase: trimmedInput, isGerman: isGermanInput)
                let newWord = Word(
                    german: isGermanInput ? trimmedInput : result.trans,
                    english: isGermanInput ? result.trans : trimmedInput,
                    etymology: result.etym
                )
                wordManager.addWord(newWord)
            } catch {
                print("Error calling translate_llm: \(error)")
                // Fallback on error
                let newWord = Word(
                    german: isGermanInput ? trimmedInput : "",
                    english: isGermanInput ? "" : trimmedInput
                )
                wordManager.addWord(newWord)
            }
        }
        inputText = ""
    }
    
    private func deleteRecentWords(at offsets: IndexSet) {
        let recentWords = Array(wordManager.words.suffix(10).reversed())
        let wordsToDelete = offsets.map { recentWords[$0] }
        
        for wordToDelete in wordsToDelete {
            wordManager.deleteWord(withId: wordToDelete.id)
        }
    }
}
