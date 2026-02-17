import Foundation

struct Word: Identifiable, Codable {
    let id: UUID
    let german: String
    let english: String
    let timestamp: Date
    var category: String = "user"
    var isLearned: Bool = false
    var folders: [String] = []
    var whySwedish: String = ""
    var etymology: String = ""
    var synonyms: String = ""
    
    init(id: UUID = UUID(), german: String, english: String, category: String = "user", folders: [String] = [], whySwedish: String = "", etymology: String = "", synonyms: String = "", timestamp: Date = Date()) {
        self.id = id
        self.german = german
        self.english = english
        self.category = category
        self.folders = folders
        self.whySwedish = whySwedish
        self.etymology = etymology
        self.synonyms = synonyms
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id
        case german
        case english
        case timestamp
        case category
        case isLearned
        case folders
        case whySwedish
        case etymology
        case synonyms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.german = try container.decode(String.self, forKey: .german)
        self.english = try container.decode(String.self, forKey: .english)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "user"
        self.isLearned = try container.decodeIfPresent(Bool.self, forKey: .isLearned) ?? false
        self.folders = try container.decodeIfPresent([String].self, forKey: .folders) ?? []
        self.whySwedish = try container.decodeIfPresent(String.self, forKey: .whySwedish) ?? ""
        self.etymology = try container.decodeIfPresent(String.self, forKey: .etymology) ?? ""
        self.synonyms = try container.decodeIfPresent(String.self, forKey: .synonyms) ?? ""
    }
}
