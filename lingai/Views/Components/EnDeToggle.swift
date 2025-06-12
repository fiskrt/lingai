import SwiftUI

struct EnDeToggle: View {
    @Binding var isGermanInput: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // English side
            Text("EN")
                .font(.caption.bold())
                .foregroundColor(isGermanInput ? .secondaryText : .white)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isGermanInput ? Color.clear : Color.duoBlue)
                        .scaleEffect(isGermanInput ? 0.8 : 1.0)
                )
            
            // German side
            Text("DE")
                .font(.caption.bold())
                .foregroundColor(isGermanInput ? .white : .secondaryText)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(isGermanInput ? Color.duoGreen : Color.clear)
                        .scaleEffect(isGermanInput ? 1.0 : 0.8)
                )
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.gray.opacity(0.2))
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isGermanInput)
        .onTapGesture {
            withAnimation {
                isGermanInput.toggle()
            }
        }
    }
}