import SwiftUI

struct WordRowView: View {
    let word: Word
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Flag icon
                Image(systemName: "flag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.duoGreen)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.duoGreen.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(word.german)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text(word.english)
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(word.timestamp.formatted(.dateTime.day().month()))
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    if word.isLearned {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.duoGreen)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surfaceBackground)
                    .shadow(color: .duoBlue.opacity(0.08), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}