import Foundation

struct Word: Identifiable, Codable {
    let id = UUID()
    let german: String
    let english: String
    let timestamp: Date
    var isLearned: Bool = false
    var etymology: String = ""
    var synonyms: String = ""
    
    init(german: String, english: String, etymology: String = "", synonyms: String = "", timestamp: Date = Date()) {
        self.german = german
        self.english = english
        self.etymology = etymology
        self.synonyms = synonyms
        self.timestamp = timestamp
    }
}