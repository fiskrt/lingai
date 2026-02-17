//
//  llm.swift
//  lingai
//
//  Created by Filip Skogh on 03.06.2025.
//


import Foundation
import AVFoundation

private func apiErrorMessage(from data: Data, fallback: String) -> String {
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let error = json["error"] as? [String: Any],
       let message = error["message"] as? String,
       !message.isEmpty {
        return message
    }

    if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
        return raw
    }

    return fallback
}

// MARK: - Configuration
class Config {
    static let shared = Config()
    private init() {}
    
    private var _mistralAPIKey: String?
    private var _openAIAPIKey: String?
    
    var mistralAPIKey: String {
        if let key = _mistralAPIKey {
            return key
        }
        
        // Try UserDefaults first
        if let savedKey = UserDefaults.standard.string(forKey: "MistralAPIKey"), !savedKey.isEmpty {
            _mistralAPIKey = savedKey
            return savedKey
        }
        
        // Fall back to plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["MistralAPIKey"] as? String, !apiKey.isEmpty else {
            return ""
        }
        _mistralAPIKey = apiKey
        return apiKey
    }
    
    var openAIAPIKey: String {
        if let key = _openAIAPIKey {
            return key
        }
        
        // Try UserDefaults first
        if let savedKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey"), !savedKey.isEmpty {
            _openAIAPIKey = savedKey
            return savedKey
        }
        
        // Fall back to plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["OpenAIAPIKey"] as? String, !apiKey.isEmpty else {
            return ""
        }
        _openAIAPIKey = apiKey
        return apiKey
    }
    
    func getCurrentMistralAPIKey() -> String {
        return mistralAPIKey
    }
    
    func getCurrentOpenAIAPIKey() -> String {
        return openAIAPIKey
    }
    
    func updateAPIKeys(mistralKey: String, openAIKey: String) {
        _mistralAPIKey = mistralKey
        _openAIAPIKey = openAIKey
        
        UserDefaults.standard.set(mistralKey, forKey: "MistralAPIKey")
        UserDefaults.standard.set(openAIKey, forKey: "OpenAIAPIKey")
    }
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
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NSError(domain: "HTTPError", code: 2, userInfo: nil)
    }

    let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
    return decoded.choices[0].message.content
}

func openAIChat(prompt: String) async throws -> String {
    guard !Config.shared.openAIAPIKey.isEmpty else {
        throw NSError(
            domain: "ConfigurationError",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is missing. Add it in Settings."]
        )
    }

    var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = [
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer \(Config.shared.openAIAPIKey)"
    ]

    let body: [String: Any] = [
        "model": "gpt-4o-mini",
        "messages": [["role": "user", "content": prompt]],
        "temperature": 0.2
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NSError(
            domain: "HTTPError",
            code: 1002,
            userInfo: [NSLocalizedDescriptionKey: "Invalid response from OpenAI API."]
        )
    }

    guard httpResponse.statusCode == 200 else {
        let message = apiErrorMessage(
            from: data,
            fallback: "OpenAI API request failed."
        )
        throw NSError(
            domain: "HTTPError",
            code: httpResponse.statusCode,
            userInfo: [NSLocalizedDescriptionKey: "OpenAI API error (\(httpResponse.statusCode)): \(message)"]
        )
    }

    let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
    return decoded.choices[0].message.content
}


struct LLMTranslation: Codable {
    let trans: String
    let why_sv: String
    let etym: String
    let synonyms: String

    enum CodingKeys: String, CodingKey {
        case trans
        case why_sv
        case etym
        case synonyms
    }

    init(trans: String, why_sv: String, etym: String, synonyms: String) {
        self.trans = trans
        self.why_sv = why_sv
        self.etym = etym
        self.synonyms = synonyms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.trans = try container.decode(String.self, forKey: .trans)
        self.why_sv = try container.decodeIfPresent(String.self, forKey: .why_sv) ?? ""
        self.etym = try container.decodeIfPresent(String.self, forKey: .etym) ?? ""
        self.synonyms = try container.decodeIfPresent(String.self, forKey: .synonyms) ?? ""
    }
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
    let direction = isGerman ? "German -> English" : "English -> German"
    let sourceLanguage = isGerman ? "German" : "English"
    let targetLanguage = isGerman ? "English" : "German"
    let prompt = """
    You are a practical German tutor for Swedish speakers.
    Task: translate the input and explain it clearly for learning.

    Translation direction: \(direction)
    Input phrase (\(sourceLanguage)): "\(phrase)"

    Return ONLY valid JSON with this exact schema:
    {
      "trans": "string",
      "why_sv": "sträng på svenska",
      "etym": "string",
      "synonyms": "string"
    }

    Requirements:
    - "trans":
      Natural and accurate translation into \(targetLanguage), preserving tone/register.
      Keep it concise.
    - "why_sv":
      Write in Swedish, relaxed and intuitive.
      Explain why this translation makes sense with a short breakdown.
      Use 2-4 short bullet-style lines separated by newline characters.
      Mention useful meaning/grammar clues when relevant.
    - "synonyms":
      Provide 2-4 German synonyms/near-synonyms.
      For each one, include the key difference in usage/nuance.
      Format as one synonym per line:
      "<word> - <important difference in Swedish>"
      Keep differences concrete and practical.
    - "etym":
      Keep it relaxed, intuitive, and learner-friendly (not formal academic style).
      If useful, connect to Swedish and/or English cognates or patterns.
      2-4 short sentences max.
    - Mention the gender

    Rules:
    - No markdown, no code fences, no extra keys.
    - If nuance is uncertain, still provide the best practical guidance.
    """

    let response = try await openAIChat(prompt: prompt)
    
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
