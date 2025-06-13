//
//  llm.swift
//  lingai
//
//  Created by Filip Skogh on 03.06.2025.
//


import Foundation

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

struct GrammarExerciseResponse: Codable {
    let exercises: [GeneratedExercise]
    
    struct GeneratedExercise: Codable {
        let type: String
        let question: String
        let correct_answer: String
        let options: [String]?
        let explanation: String
        let difficulty: String
        let used_words: [String]
    }
}

func generate_grammar_exercises(words: [String], exerciseType: String, count: Int = 5) async throws -> GrammarExerciseResponse {
    let wordList = words.joined(separator: ", ")
    
    let exerciseInstructions: String
    switch exerciseType {
    case "fill_blank":
        exerciseInstructions = """
        - Create sentences with blanks for articles (der/die/das), cases (accusative/dative/genitive), or verb forms
        - Format: "Ich gehe in ___ Park" with correct answer "den" (accusative)
        - Options should include der, die, das, den, dem, des as appropriate
        """
    case "sentence_building":
        exerciseInstructions = """
        - Provide scrambled German words that form a correct sentence
        - Format question as: "Build a sentence: [word1, word2, word3, word4]"
        - Correct answer should be the properly ordered sentence
        - No options needed (options can be empty array)
        """
    case "case_selection":
        exerciseInstructions = """
        - Focus on correct case usage (Nominativ, Akkusativ, Dativ, Genitiv)
        - Format: "Complete: Ich sehe ___ Mann" with options and correct case
        - Options should include different case forms of the same article/adjective
        """
    case "verb_conjugation":
        exerciseInstructions = """
        - Present verb infinitives and ask for correct conjugation
        - Format: "Conjugate 'sein' for 'wir': wir ___" with correct answer "sind"
        - Include common verb forms and tenses
        """
    default:
        exerciseInstructions = "Create general grammar exercises"
    }
    
    let prompt = """
    Create \(count) German grammar exercises using these vocabulary words when possible: \(wordList).
    Exercise type: \(exerciseType)
    
    \(exerciseInstructions)
    
    Respond only with JSON in this exact format: {"exercises": [{"type": "\(exerciseType)", "question": "question here", "correct_answer": "answer", "options": ["option1", "option2", "correct_answer", "option3"], "explanation": "brief explanation of the grammar rule", "difficulty": "beginner", "used_words": ["word1", "word2"]}]}
    
    Rules:
    - Each exercise must include a clear question
    - Correct answer must be precise and unambiguous
    - Include 3-4 options for multiple choice (except sentence_building which can have empty options)
    - Explanation should be 1-2 sentences explaining the grammar rule
    - Difficulty should be "beginner", "intermediate", or "advanced"
    - used_words should list vocabulary words that appear in the exercise
    - Make exercises progressively more challenging
    - Ensure grammatical accuracy
    """
    
    let response = try await mistralChat(prompt: prompt)
    
    guard let jsonStart = response.firstIndex(of: "{"),
          let jsonEnd = response.lastIndex(of: "}") else {
        throw NSError(domain: "ParseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find JSON in response."])
    }

    let jsonSubstring = response[jsonStart...jsonEnd]
    let jsonData = Data(jsonSubstring.utf8)

    let grammarResponse = try JSONDecoder().decode(GrammarExerciseResponse.self, from: jsonData)
    return grammarResponse
}
