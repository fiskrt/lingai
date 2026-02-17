import SwiftUI

private struct GrammarTopic: Identifiable, Hashable {
    let id: String
    let label: String
}

struct GrammarPracticeView: View {
    @State private var selectedTopics: Set<String> = ["modalverbs"]
    @State private var selectedLevel = "A1"

    @State private var englishSentence = ""
    @State private var studentTranslation = ""
    @State private var gradingFeedback = ""
    @State private var sentenceBatch: [LLMGrammarTranslationPrompt] = []
    @State private var sentenceBatchIndex = 0

    @State private var isGeneratingSentence = false
    @State private var isGrading = false
    @State private var errorMessage: String?
    @State private var isSetupExpanded = true
    @FocusState private var isTranslationEditorFocused: Bool

    private let levelOptions = ["A1", "A2", "B1"]
    private let topics: [GrammarTopic] = [
        .init(id: "modalverbs", label: "Modal Verbs"),
        .init(id: "past", label: "Past"),
        .init(id: "vor_seit", label: "vor/seit")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.duoOrange.opacity(0.1), Color.duoYellow.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            header
                            setupCard
                            sentenceCard
                            inputCard
                            feedbackCard
                                .id("feedbackCard")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 30)
                    }
                    .onChange(of: isGrading) { _, newValue in
                        if newValue {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo("feedbackCard", anchor: .top)
                            }
                        }
                    }
                    .onChange(of: gradingFeedback) { _, newValue in
                        if !newValue.isEmpty {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo("feedbackCard", anchor: .top)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Grammar", isPresented: Binding(
                get: { errorMessage != nil },
                set: { newValue in
                    if !newValue {
                        errorMessage = nil
                    }
                }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Grammar Translation Quiz")
                .font(.title2.bold())
                .foregroundColor(.primaryText)
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Exercise Setup")
                    .font(.caption.bold())
                    .foregroundColor(.secondaryText)

                Spacer()

                Button {
                    isTranslationEditorFocused = false
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSetupExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondaryText)
                        .rotationEffect(.degrees(isSetupExpanded ? 0 : -90))
                }
                .buttonStyle(.plain)
            }

            if isSetupExpanded {
                HStack(spacing: 8) {
                    ForEach(topics) { topic in
                        Button(topic.label) {
                            toggleTopic(topic.id)
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedTopics.contains(topic.id) ? .white : .duoOrange)
                        .background(
                            Capsule().fill(
                                selectedTopics.contains(topic.id)
                                ? LinearGradient(colors: [.duoOrange, .duoRed], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.duoOrange.opacity(0.12)], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                    }
                }

                HStack {
                    Text("Level")
                        .font(.caption.bold())
                        .foregroundColor(.secondaryText)
                    Spacer()
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(levelOptions, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)
                }

                Button(action: generateSentence) {
                    HStack {
                        if isGeneratingSentence {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(isGeneratingSentence ? "Generating..." : (englishSentence.isEmpty ? "Generate 5 Sentences" : "New 5 Sentences"))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.duoOrange)
                    .cornerRadius(12)
                }
                .disabled(isGeneratingSentence || selectedTopics.isEmpty)
                .opacity((isGeneratingSentence || selectedTopics.isEmpty) ? 0.7 : 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isSetupExpanded {
                isTranslationEditorFocused = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSetupExpanded = true
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private var sentenceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if englishSentence.isEmpty {
                Text("Generate a sentence to start.")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            } else {
                Text("\"\(englishSentence)\"")
                    .font(.headline)
                    .foregroundColor(.primaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your German Translation")
                .font(.caption.bold())
                .foregroundColor(.secondaryText)

            TextEditor(text: $studentTranslation)
                .frame(minHeight: 90)
                .focused($isTranslationEditorFocused)
                .padding(8)
                .background(Color.surfaceBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.duoBlue.opacity(0.25), lineWidth: 1)
                )

            Button(action: gradeAnswer) {
                HStack {
                    if isGrading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    Text(isGrading ? "Grading..." : "Check My Answer")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.duoBlue)
                .cornerRadius(12)
            }
            .disabled(isGrading || englishSentence.isEmpty || studentTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity((isGrading || englishSentence.isEmpty || studentTranslation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.7 : 1)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private var feedbackCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if gradingFeedback.isEmpty {
                Text("Submit your translation to get grading and beginner-level tips.")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(gradingFeedback.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                        if line.isEmpty {
                            Text(" ")
                                .font(.subheadline)
                                .foregroundColor(.primaryText)
                        } else if let markdownLine = try? AttributedString(
                            markdown: line,
                            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
                        ) {
                            Text(markdownLine)
                                .font(.subheadline)
                                .foregroundColor(.primaryText)
                        } else {
                            Text(line)
                                .font(.subheadline)
                                .foregroundColor(.primaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.surfaceBackground))

                Button("Next Sentence") {
                    nextSentence()
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.duoPurple)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.cardBackground))
    }

    private func toggleTopic(_ id: String) {
        if selectedTopics.contains(id) {
            if selectedTopics.count > 1 {
                selectedTopics.remove(id)
            }
        } else {
            selectedTopics.insert(id)
        }
    }

    private func generateSentence() {
        guard !selectedTopics.isEmpty else { return }
        isGeneratingSentence = true
        errorMessage = nil

        Task {
            do {
                let examples = try await generateGrammarTranslationSentenceBatch(
                    topics: Array(selectedTopics).sorted(),
                    level: selectedLevel,
                    count: 5
                )
                await MainActor.run {
                    sentenceBatch = examples
                    sentenceBatchIndex = 0
                    applyCurrentBatchSentence()
                    isSetupExpanded = false
                    isGeneratingSentence = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not generate sentence: \(error.localizedDescription)"
                    isGeneratingSentence = false
                }
            }
        }
    }

    private func gradeAnswer() {
        guard !englishSentence.isEmpty else { return }
        let submission = studentTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submission.isEmpty else { return }

        isTranslationEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        isGrading = true
        errorMessage = nil

        Task {
            do {
                let result = try await gradeGrammarTranslation(
                    englishSentence: englishSentence,
                    studentGerman: submission,
                    topics: Array(selectedTopics).sorted()
                )
                await MainActor.run {
                    gradingFeedback = result
                    isGrading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not grade translation: \(error.localizedDescription)"
                    isGrading = false
                }
            }
        }
    }

    private func applyCurrentBatchSentence() {
        guard sentenceBatch.indices.contains(sentenceBatchIndex) else {
            englishSentence = ""
            studentTranslation = ""
            gradingFeedback = ""
            return
        }

        let current = sentenceBatch[sentenceBatchIndex]
        englishSentence = current.english_sentence
        studentTranslation = ""
        gradingFeedback = ""
    }

    private func nextSentence() {
        if sentenceBatchIndex + 1 < sentenceBatch.count {
            sentenceBatchIndex += 1
            applyCurrentBatchSentence()
            return
        }

        generateSentence()
    }
}
