//
//  llm.swift
//  lingai
//
//  Created by Filip Skogh on 03.06.2025.
//


import Foundation
import AVFoundation

// MARK: - Configuration
class Config {
    static let shared = Config()
    private init() {}
    
    lazy var mistralAPIKey: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["MistralAPIKey"] as? String else {
            fatalError("Config.plist not found or MistralAPIKey not set")
        }
        return apiKey
    }()
    
    lazy var openAIAPIKey: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["OpenAIAPIKey"] as? String else {
            fatalError("Config.plist not found or OpenAIAPIKey not set")
        }
        return apiKey
    }()
}

struct ChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage

    struct Choice: Codable {
        let index: Int
        let message: Message
        let finish_reason: String

        struct Message: Codable {
            let role: String
            let tool_calls: [String]?
            let content: String
        }
    }

    struct Usage: Codable {
        let prompt_tokens: Int
        let total_tokens: Int
        let completion_tokens: Int
    }
}


func mistralChat(prompt: String) async throws -> String {
    var request = URLRequest(url: URL(string: "https://api.mistral.ai/v1/chat/completions")!)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = [
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer \(Config.shared.mistralAPIKey)"
    ]

    let body: [String: Any] = [
        "model": "mistral-large-latest",
        "messages": [["role": "user", "content": prompt]],
        "response_format": ["type": "json_object"]
    ]
    let jsonData = try JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted])
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NSError(domain: "HTTPError", code: 2, userInfo: nil)
    }

    let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
    return decoded.choices[0].message.content
}


struct LLMTranslation: Codable {
    let trans: String
    let etym: String
    let synonyms: String
}

struct LLMReadingPassage: Codable {
    let title: String
    let content: String
    let questions: [LLMQuestion]
    
    struct LLMQuestion: Codable {
        let question: String
        let options: [String]
        let correct_answer: Int
    }
}

func translate_llm(phrase: String, isGerman: Bool) async throws -> LLMTranslation {
    let prompt: String
    
    if isGerman{
        prompt = """
        Respond only with a JSON following format: {"trans":"translation from German to English of '\(phrase)' here", "etym":"etymology of the german phrase here given in English", "synonyms":"2-3 German synonyms for '\(phrase)' separated by commas"}.
        """
    } else {
        prompt = """
        Respond only with a JSON following format: {"trans":"translation from English to German of '\(phrase)' here", "etym":"etymology of the german phrase here given in English", "synonyms":"2-3 German synonyms for the translated word separated by commas"}.
        """
    }

    let response = try await mistralChat(prompt: prompt)
    
    guard let jsonStart = response.firstIndex(of: "{"),
          let jsonEnd = response.lastIndex(of: "}") else {
        throw NSError(domain: "ParseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find JSON in response."])
    }

    let jsonSubstring = response[jsonStart...jsonEnd]
    let jsonData = Data(jsonSubstring.utf8)

    let translation = try JSONDecoder().decode(LLMTranslation.self, from: jsonData)
    return translation
}

func generateReadingPassage(vocabularyWords: [String], customInstructions: String = "") async throws -> LLMReadingPassage {
    let wordsString = vocabularyWords.joined(separator: ", ")
    
    let customPrompt = customInstructions.isEmpty ? "" : "\n\nAdditional instructions: \(customInstructions)"
    
    let prompt = """
    Create a German reading comprehension exercise. Write a ~300 word German text that naturally incorporates these vocabulary words: \(wordsString).\(customPrompt)
    
    Then create 4-5 multiple choice questions in German about the text comprehension.
    
    Respond only with JSON in this exact format:
    {
        "title": "Title for the reading passage in German",
        "content": "The 300-word German text here",
        "questions": [
            {
                "question": "Question in German",
                "options": ["Option A", "Option B", "Option C", "Option D"],
                "correct_answer": 0
            }
        ]
    }
    
    Make the text engaging and educational. Questions should test comprehension, not just vocabulary recall.
    """
    
    let response = try await mistralChat(prompt: prompt)
    
    guard let jsonStart = response.firstIndex(of: "{"),
          let jsonEnd = response.lastIndex(of: "}") else {
        throw NSError(domain: "ParseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find JSON in response."])
    }
    
    let jsonSubstring = response[jsonStart...jsonEnd]
    let jsonData = Data(jsonSubstring.utf8)
    
    let passage = try JSONDecoder().decode(LLMReadingPassage.self, from: jsonData)
    return passage
}

// MARK: - Text-to-Speech Manager
class TTSManager {
    static let shared = TTSManager()
    private init() {}
    
    func generateSpeech(text: String, filename: String) async throws -> URL {
        let first50 = String(text.prefix(50))
        let last50 = String(text.suffix(50))
        let totalChars = text.count
        
        print("🔊 OpenAI TTS API Call:")
        print("📝 First 50 chars: \"\(first50)\"")
        print("📝 Last 50 chars: \"\(last50)\"")
        print("📊 Total characters: \(totalChars)")
        print("🎵 Voice: coral")
        print("📁 Filename: \(filename)")
        
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Authorization": "Bearer \(Config.shared.openAIAPIKey)",
            "Content-Type": "application/json"
        ]
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini-tts",
            "input": text,
            "voice": "coral",
            "instructions": "Speak in a clear, natural tone suitable for German language learners."
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "TTSError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate speech"])
        }
        
        // Save audio file to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("\(filename).mp3")
        
        try data.write(to: audioURL)
        
        return audioURL
    }
    
    func generateSpeechInBackground(text: String, filename: String) {
        Task {
            do {
                _ = try await generateSpeech(text: text, filename: filename)
                print("TTS generated successfully for: \(filename)")
            } catch {
                print("TTS generation failed: \(error)")
            }
        }
    }
}
