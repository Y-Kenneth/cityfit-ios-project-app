import SwiftUI

struct SignUpView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var canContinue: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty && password == confirmPassword
    }

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Create your account")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)

                VStack(spacing: 14) {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color.cityCard)
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    SecureField("Password", text: $password)
                        .padding(14)
                        .background(Color.cityCard)
                        .cornerRadius(12)
                        .foregroundColor(.white)

                    SecureField("Confirm password", text: $confirmPassword)
                        .padding(14)
                        .background(Color.cityCard)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }

                NavigationLink {
                    CharacterSelectView(username: username)
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canContinue ? Color.cityAccent : Color.citySubtext.opacity(0.4))
                        .cornerRadius(14)
                }
                .disabled(!canContinue)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpView()
        }
    }
}
