import SwiftUI

struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color
    var isEmpty: Bool = false
    var showIcon: Bool = true
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if showIcon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(content)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(isEmpty ? .secondaryText : .primaryText)
                    .italic(isEmpty)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
