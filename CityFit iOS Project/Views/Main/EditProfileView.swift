import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username: String
    @State private var selectedCharacter: CharacterType

    init(profile: UserProfile) {
        _username = State(initialValue: profile.username)
        _selectedCharacter = State(initialValue: profile.character)
    }

    private var canSave: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cityBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Username")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.citySubtext)
                            TextField("Username", text: $username)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.cityCard)
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Character")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.citySubtext)
                            CharacterPickerGrid(selected: $selectedCharacter)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.citySubtext)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        profileViewModel.updateProfile(username: username, character: selectedCharacter)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(profile: UserProfile.new(username: "Kenneth", character: .ninja))
            .environmentObject(ProfileViewModel())
    }
}
