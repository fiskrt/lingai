import SwiftUI

struct SettingsView: View {
    @State private var mistralAPIKey: String = ""
    @State private var openAIAPIKey: String = ""
    @State private var showingSaveConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching the app theme
                LinearGradient(
                    colors: [Color.duoBlue.opacity(0.05), Color.duoGreen.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header section
                        VStack(spacing: 8) {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.duoBlue)
                            
                            Text("API Configuration")
                                .font(.title2.bold())
                                .foregroundColor(.primaryText)
                            
                            Text("Configure your API keys to enable translation and audio features")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // API Keys Section
                        VStack(spacing: 16) {
                            // Mistral API Key
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "translate")
                                        .foregroundColor(.duoBlue)
                                    Text("Mistral API Key")
                                        .font(.headline)
                                        .foregroundColor(.primaryText)
                                    Spacer()
                                }
                                
                                Text("Used for reading passage generation")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                
                                SecureField("Enter your Mistral API key", text: $mistralAPIKey)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(12)
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(mistralAPIKey.isEmpty ? Color.gray.opacity(0.3) : Color.duoBlue, lineWidth: 1)
                                    )
                            }
                            .padding()
                            .background(Color.surfaceBackground)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            // OpenAI API Key
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.duoGreen)
                                    Text("OpenAI API Key")
                                        .font(.headline)
                                        .foregroundColor(.primaryText)
                                    Spacer()
                                }
                                
                                Text("Used for translations and text-to-speech audio generation")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                
                                SecureField("Enter your OpenAI API key", text: $openAIAPIKey)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(12)
                                    .background(Color.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(openAIAPIKey.isEmpty ? Color.gray.opacity(0.3) : Color.duoBlue, lineWidth: 1)
                                    )
                            }
                            .padding()
                            .background(Color.surfaceBackground)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Save Button
                        Button(action: {
                            saveAPIKeys()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Configuration")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.duoBlue, Color.duoBlue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.duoBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(mistralAPIKey.isEmpty || openAIAPIKey.isEmpty)
                        .opacity(mistralAPIKey.isEmpty || openAIAPIKey.isEmpty ? 0.6 : 1.0)
                        
                        // Info section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.duoOrange)
                                Text("Important")
                                    .font(.headline)
                                    .foregroundColor(.primaryText)
                                Spacer()
                            }
                            
                            Text("API keys are stored solely on your device.\nRequests to APIs are encrypted over https.")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                        }
                        .padding()
                        .background(Color.surfaceBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.duoBlue)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentAPIKeys()
        }
        .alert("Configuration Saved", isPresented: $showingSaveConfirmation) {
            Button("Great!") { 
                dismiss()
            }
        } message: {
            Text("Your API keys have been saved and are ready to use.")
        }
    }
    
    private func loadCurrentAPIKeys() {
        mistralAPIKey = Config.shared.getCurrentMistralAPIKey()
        openAIAPIKey = Config.shared.getCurrentOpenAIAPIKey()
    }
    
    private func saveAPIKeys() {
        Config.shared.updateAPIKeys(mistralKey: mistralAPIKey, openAIKey: openAIAPIKey)
        showingSaveConfirmation = true
    }
}

#Preview {
    SettingsView()
}
