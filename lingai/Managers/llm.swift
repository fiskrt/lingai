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
}

func translate_llm(phrase: String, isGerman: Bool) async throws -> LLMTranslation {
    let prompt: String
    
    if isGerman{
        prompt = """
        Respond only with a JSON folloing format: {"trans":"translation from German to English of '\(phrase)' here", "etym":"etymology of the german phrase here given in English"}.
        """
    } else {
        prompt = """
        Respond only with a JSON folloing format: {"trans":"translation from English to German of '\(phrase)' here", "etym":"etymology of the german phrase here given in English"}.
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
