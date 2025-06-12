import SwiftUI

extension Color {
    static let duoGreen = Color(red: 0.33, green: 0.78, blue: 0.32)
    static let duoBlue = Color(red: 0.11, green: 0.63, blue: 0.94)
    static let duoOrange = Color(red: 1.0, green: 0.57, blue: 0.0)
    static let duoPurple = Color(red: 0.51, green: 0.29, blue: 0.96)
    static let duoYellow = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let duoRed = Color(red: 0.94, green: 0.33, blue: 0.31)
    
    // Adaptive colors for dark/light mode
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
    static let surfaceBackground = Color(UIColor.systemBackground)
}