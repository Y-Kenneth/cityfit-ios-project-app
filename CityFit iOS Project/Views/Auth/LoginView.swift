import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel

    @State private var username = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "map.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.cityAccent)

                Text("Welcome back")
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
                }

                Button {
                    profileViewModel.logIn(username: username.isEmpty ? "CityFitter" : username)
                } label: {
                    Text("Log In")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cityAccent)
                        .cornerRadius(14)
                }

                NavigationLink {
                    SignUpView()
                } label: {
                    Text("New here? **Sign Up**")
                        .font(.system(size: 14))
                        .foregroundColor(.citySubtext)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationBarHidden(true)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
        }
        .environmentObject(ProfileViewModel())
    }
}
