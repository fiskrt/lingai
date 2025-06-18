import SwiftUI






struct ContentView: View {
    @StateObject private var wordManager = WordManager()
    
    var body: some View {
        TabView {
            WordInputView(wordManager: wordManager)
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
    }
}
