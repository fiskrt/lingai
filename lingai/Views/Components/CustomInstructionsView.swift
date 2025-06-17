import SwiftUI

struct CustomInstructionsView: View {
    @Binding var customInstructions: String
    @Binding var isPresented: Bool
    let onGenerate: () -> Void
    
    @State private var placeholder = "Enter custom instructions for your reading passage..."
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom Instructions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Customize your reading passage with specific instructions like topic, difficulty level, style, etc.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Examples:")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• \"A1 level text about animals\"")
                            Text("• \"Story about the Titanic, intermediate level\"")
                            Text("• \"Modern technology theme, B2 level\"")
                            Text("• \"Historical text about German culture\"")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions (Optional)")
                        .font(.headline)
                    
                    TextEditor(text: $customInstructions)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Generate Passage") {
                        onGenerate()
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Reading Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
}