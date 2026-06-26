import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var username: String
    @State private var selectedCharacter: CharacterType
    @State private var gender: Gender
    @State private var weightKg: Double
    @State private var heightCm: Double
    @State private var isHealthKitConnected: Bool
    @State private var showHealthUnavailableAlert = false

    init(profile: UserProfile) {
        _username = State(initialValue: profile.username)
        _selectedCharacter = State(initialValue: profile.character)
        _gender = State(initialValue: profile.gender)
        _weightKg = State(initialValue: profile.weightKg)
        _heightCm = State(initialValue: profile.heightCm)
        _isHealthKitConnected = State(initialValue: profile.isHealthKitConnected)
    }

    private var canSave: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Username")
                                .font(.game(size: 13, weight: .semibold))
                                .foregroundColor(.citySubtext)
                            TextField("Username", text: $username)
                                .font(.game(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.cityCard)
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Character")
                                .font(.game(size: 13, weight: .semibold))
                                .foregroundColor(.citySubtext)
                            CharacterPickerGrid(selected: $selectedCharacter)
                        }

                        healthSection
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
                        if !isHealthKitConnected {
                            profileViewModel.updateHealthInfo(gender: gender, weightKg: weightKg, heightCm: heightCm)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!canSave)
                }
            }
            .alert("Apple Health Unavailable", isPresented: $showHealthUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Health data isn't available on this device (e.g. the Simulator). Use the manual fields instead.")
            }
            .onReceive(profileViewModel.$profile) { updated in
                guard let updated else { return }
                isHealthKitConnected = updated.isHealthKitConnected
                if updated.isHealthKitConnected {
                    gender = updated.gender
                    weightKg = updated.weightKg
                    heightCm = updated.heightCm
                }
            }
            .onReceive(profileViewModel.$healthKitUnavailable) { unavailable in
                if unavailable { showHealthUnavailableAlert = true }
            }
        }
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Health Info")
                    .font(.game(size: 13, weight: .semibold))
                    .foregroundColor(.citySubtext)
                Spacer()
                if isHealthKitConnected {
                    Label("Synced from Health", systemImage: "heart.fill")
                        .font(.game(size: 11, weight: .semibold))
                        .foregroundColor(.cityGreen)
                }
            }

            if isHealthKitConnected {
                connectedHealthSummary
                Button(role: .destructive) {
                    profileViewModel.disconnectHealthKit()
                } label: {
                    Text("Disconnect from Apple Health")
                        .font(.game(size: 14, weight: .semibold))
                        .foregroundColor(.red.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
            } else {
                HealthInfoFormView(gender: $gender, weightKg: $weightKg, heightCm: $heightCm)
                connectHealthButton
            }
        }
    }

    private var connectedHealthSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            healthRow(label: "Gender", value: gender.displayName)
            healthRow(label: "Weight", value: String(format: "%.1f kg", weightKg))
            healthRow(label: "Height", value: String(format: "%.0f cm", heightCm))
            if let hr = profileViewModel.profile?.restingHeartRate {
                healthRow(label: "Resting Heart Rate", value: "\(hr) bpm")
            }
            if let energy = profileViewModel.profile?.activeEnergyKcal {
                healthRow(label: "Active Energy", value: String(format: "%.0f kcal", energy))
            }
        }
        .padding(14)
        .background(Color.cityCard)
        .cornerRadius(12)
    }

    private func healthRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.game(size: 13))
                .foregroundColor(.citySubtext)
            Spacer()
            Text(value)
                .font(.game(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var connectHealthButton: some View {
        Button {
            profileViewModel.connectToHealthKit()
        } label: {
            HStack(spacing: 8) {
                if profileViewModel.isConnectingHealthKit {
                    ProgressView().tint(.black)
                } else {
                    Image(systemName: "heart.fill")
                }
                Text(profileViewModel.isConnectingHealthKit ? "Connecting…" : "Connect to Apple Health")
            }
            .font(.game(size: 15, weight: .bold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.cityAccent)
            .cornerRadius(12)
        }
        .disabled(profileViewModel.isConnectingHealthKit)
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(profile: UserProfile.new(username: "Kenneth", character: .ninja))
            .environmentObject(ProfileViewModel())
    }
}
