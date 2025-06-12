import SwiftUI

// MARK: - Period Button
struct PeriodButton: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(days)")
                    .font(.headline.bold())
                    .foregroundColor(isSelected ? .white : .duoPurple)
                
                Text("day\(days == 1 ? "" : "s")")
                    .font(.caption2.bold())
                    .foregroundColor(isSelected ? .white : .duoPurple.opacity(0.7))
            }
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(
                        isSelected ?
                        LinearGradient(colors: [.duoPurple, .duoBlue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.duoPurple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

// MARK: - Progress Card
struct ProgressCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondaryText)
                .textCase(.uppercase)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Navigation Button
struct NavigationButton: View {
    let title: String
    let icon: String
    let isDisabled: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if icon == "chevron.left" {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                if icon == "chevron.right" {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(isDisabled ? .secondaryText : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? Color.gray.opacity(0.3) : color)
            )
        }
        .disabled(isDisabled)
    }
}