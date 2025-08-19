import SwiftUI






struct ContentView: View {
    @StateObject private var wordManager = WordManager()
    @State private var showingSettings = false
    
    var body: some View {
        TabView {
            WordInputView(wordManager: wordManager, showingSettings: $showingSettings)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Words")
                }
            
            VocabularyPracticeView(wordManager: wordManager)
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Practice")
                }
            
            ReadingView(wordManager: wordManager)
                .tabItem {
                    Image("mysymbol")
                    Text("Comprehend")
                }
            
            GrammarPracticeView()
                .tabItem {
                    Image(systemName: "text.book.closed.fill")
                    Text("Grammar")
                }
        }
        .accentColor(.duoBlue)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}
