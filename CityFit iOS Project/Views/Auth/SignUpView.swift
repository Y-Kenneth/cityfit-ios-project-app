import SwiftUI

// New users sign in via Google on LoginView and land here to pick a character.
// Username is pre-filled from their Google display name.
struct SignUpView: View {
    let username: String

    var body: some View {
        CharacterSelectView(username: username)
            .navigationBarHidden(true)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpView(username: "Kenneth")
        }
    }
}
