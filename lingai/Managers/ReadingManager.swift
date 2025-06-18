import Foundation
import AVFoundation

class ReadingManager: NSObject, ObservableObject {
    @Published var readingPassages: [ReadingPassage] = []
    @Published var completedSessions: [ReadingSession] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var isPlayingAudio = false
    @Published var hasAudioBeenStarted = false
    
    private let userDefaults = UserDefaults.standard
    private var audioPlayer: AVAudioPlayer?
    private var currentPassageId: UUID?
    private let passagesKey = "readingPassages"
    private let sessionsKey = "readingSessions"
    
    override init() {
        super.init()
        loadPassages()
        loadSessions()
    }
    
    func createReadingPassage(from words: [Word], customInstructions: String = "") async {
        DispatchQueue.main.async {
            self.isGenerating = true
            self.errorMessage = nil
        }
        
        let vocabularyWords = words.map { $0.german }
        guard !vocabularyWords.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "No vocabulary words available"
                self.isGenerating = false
            }
            return
        }
        
        do {
            let llmPassage = try await generateReadingPassage(vocabularyWords: vocabularyWords, customInstructions: customInstructions)
            
            let questions = llmPassage.questions.map { llmQuestion in
                ComprehensionQuestion(
                    question: llmQuestion.question,
                    options: llmQuestion.options,
                    correctAnswerIndex: llmQuestion.correct_answer
                )
            }
            
            let passage = ReadingPassage(
                title: llmPassage.title,
                content: llmPassage.content,
                questions: questions,
                vocabularyWords: vocabularyWords
            )
            
            DispatchQueue.main.async {
                self.readingPassages.append(passage)
                self.savePassages()
                self.isGenerating = false
                
                // Generate TTS audio in background
                let audioFilename = "reading_\(passage.id.uuidString)"
                TTSManager.shared.generateSpeechInBackground(text: passage.content, filename: audioFilename)
                
                // Update passage with audio file path
                if let index = self.readingPassages.firstIndex(where: { $0.id == passage.id }) {
                    self.readingPassages[index].audioFilePath = audioFilename
                    self.savePassages()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to generate reading passage: \(error.localizedDescription)"
                self.isGenerating = false
            }
        }
    }
    
    func completeSession(for passageId: UUID, answers: [Int]) {
        guard let passage = readingPassages.first(where: { $0.id == passageId }) else { return }
        
        let score = calculateScore(answers: answers, questions: passage.questions)
        let session = ReadingSession(passageId: passageId, answers: answers, score: score)
        
        completedSessions.append(session)
        saveSessions()
    }
    
    private func calculateScore(answers: [Int], questions: [ComprehensionQuestion]) -> Int {
        var correct = 0
        for (index, answer) in answers.enumerated() {
            if index < questions.count && answer == questions[index].correctAnswerIndex {
                correct += 1
            }
        }
        return Int((Double(correct) / Double(questions.count)) * 100)
    }
    
    func playAudio(for passage: ReadingPassage) {
        guard let audioURL = getAudioURL(for: passage) else { return }
        
        // If this is a different passage, reset audio state
        if currentPassageId != passage.id {
            resetAudioStateForNewPassage()
            currentPassageId = passage.id
        }
        
        do {
            try configureAudioSession()
            try setupAudioPlayer(with: audioURL)
            audioPlayer?.play()
            isPlayingAudio = true
            hasAudioBeenStarted = true
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        isPlayingAudio = false
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlayingAudio = false
        deactivateAudioSession()
    }
    
    func pauseAudioOnExit() {
        if isPlayingAudio {
            audioPlayer?.pause()
            isPlayingAudio = false
        }
        // Don't deactivate session or nil out player - keep state for resume
    }
    
    func restartAudio(for passage: ReadingPassage) {
        guard let audioURL = getAudioURL(for: passage) else { return }
        
        // Update current passage if different
        if currentPassageId != passage.id {
            currentPassageId = passage.id
        }
        
        do {
            try configureAudioSession()
            try setupAudioPlayer(with: audioURL)
            audioPlayer?.currentTime = 0  // Reset to beginning
            audioPlayer?.play()
            isPlayingAudio = true
            hasAudioBeenStarted = true
        } catch {
            print("Failed to restart audio: \(error)")
        }
    }
    
    func cleanupAudio() {
        if isPlayingAudio {
            audioPlayer?.stop()
            isPlayingAudio = false
        }
        audioPlayer = nil
        hasAudioBeenStarted = false
        currentPassageId = nil
        deactivateAudioSession()
    }
    
    private func resetAudioStateForNewPassage() {
        if isPlayingAudio {
            audioPlayer?.stop()
            isPlayingAudio = false
        }
        audioPlayer = nil
        hasAudioBeenStarted = false
        deactivateAudioSession()
    }
    
    func checkPassageChange(for passage: ReadingPassage) {
        // Reset state only if this is a different passage
        if currentPassageId != nil && currentPassageId != passage.id {
            resetAudioStateForNewPassage()
            currentPassageId = passage.id
        } else if currentPassageId == nil {
            currentPassageId = passage.id
        }
    }
    
    // MARK: - Private Audio Helpers
    private func configureAudioSession() throws {
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
        try AVAudioSession.sharedInstance().setActive(true)
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func getAudioURL(for passage: ReadingPassage) -> URL? {
        guard let audioFilePath = passage.audioFilePath else {
            print("No audio file available for this passage")
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("\(audioFilePath).mp3")
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("Audio file does not exist at path: \(audioURL.path)")
            return nil
        }
        
        return audioURL
    }
    
    private func setupAudioPlayer(with url: URL) throws {
        if audioPlayer == nil || audioPlayer?.url != url {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        }
    }
    
    private func loadPassages() {
        if let data = userDefaults.data(forKey: passagesKey),
           let passages = try? JSONDecoder().decode([ReadingPassage].self, from: data) {
            self.readingPassages = passages
        }
    }
    
    private func savePassages() {
        if let data = try? JSONEncoder().encode(readingPassages) {
            userDefaults.set(data, forKey: passagesKey)
        }
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let sessions = try? JSONDecoder().decode([ReadingSession].self, from: data) {
            self.completedSessions = sessions
        }
    }
    
    private func saveSessions() {
        if let data = try? JSONEncoder().encode(completedSessions) {
            userDefaults.set(data, forKey: sessionsKey)
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension ReadingManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlayingAudio = false
        deactivateAudioSession()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlayingAudio = false
        if let error = error {
            print("Audio player decode error: \(error)")
        }
        deactivateAudioSession()
    }
}