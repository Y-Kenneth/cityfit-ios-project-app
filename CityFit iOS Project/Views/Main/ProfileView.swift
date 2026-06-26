import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var missionViewModel: MissionViewModel

    @State private var showLogOutConfirm = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                if let profile = profileViewModel.profile {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Character + level — tap to edit
                            Button {
                                showEditProfile = true
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack(alignment: .bottomTrailing) {
                                        CharacterAvatarView(character: profile.character, size: 100)
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.game(size: 22))
                                            .foregroundColor(.cityAccent)
                                            .background(Color.cityBackground, in: Circle())
                                    }

                                    HStack(spacing: 6) {
                                        Text(profile.username)
                                            .font(.game(size: 24, weight: .heavy))
                                            .foregroundColor(.white)
                                        Image(systemName: "pencil")
                                            .font(.game(size: 13, weight: .semibold))
                                            .foregroundColor(.citySubtext)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 10)

                            EXPBarView(level: profile.level, currentEXP: profile.currentEXP)
                                .padding(.horizontal, 30)

                            // Stats
                            HStack(spacing: 12) {
                                statBox(value: "\(profile.totalSteps)", label: "Total Steps", icon: "figure.walk")
                                statBox(value: "\(profile.missionsCompleted)", label: "Missions", icon: "target")
                                statBox(value: "\(profile.streak)🔥", label: "Streak", icon: "flame.fill")
                            }
                            .padding(.horizontal, 16)

                            // Weekly recap
                            weeklyChart(steps: profile.weeklySteps)
                                .padding(.horizontal, 16)

                            healthSection(profile)
                                .padding(.horizontal, 16)

                            Text("Joined \(profile.joinDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.game(size: 12))
                                .foregroundColor(.citySubtext)

                            Button {
                                showLogOutConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .font(.game(size: 15, weight: .semibold))
                                .foregroundColor(.red.opacity(0.85))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.bottom, 90)
                        }
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .confirmationDialog("Log out of CityFit?", isPresented: $showLogOutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                missionViewModel.resetAll()
                profileViewModel.logOut()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showEditProfile) {
            if let profile = profileViewModel.profile {
                EditProfileView(profile: profile)
            }
        }
    }

    private func statBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.game(size: 18))
                .foregroundColor(.cityAccent)
            Text(value)
                .font(.game(size: 17, weight: .heavy))
                .foregroundColor(.white)
            Text(label)
                .font(.game(size: 11))
                .foregroundColor(.citySubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cityCard)
        .cornerRadius(14)
    }

    /// weeklySteps[0] is today — render oldest day on the left.
    private func weeklyChart(steps: [Int]) -> some View {
        let maxSteps = max(steps.max() ?? 1, 1)
        let ordered = Array(steps.reversed())
        return VStack(alignment: .leading, spacing: 10) {
            Text("This Week")
                .font(.game(size: 16, weight: .heavy))
                .foregroundColor(.white)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(ordered.indices, id: \.self) { index in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == ordered.count - 1 ? Color.cityGreen : Color.cityAccent.opacity(0.5))
                            .frame(height: max(CGFloat(ordered[index]) / CGFloat(maxSteps) * 80, 4))
                        Text(dayLabel(daysAgo: ordered.count - 1 - index))
                            .font(.game(size: 10))
                            .foregroundColor(.citySubtext)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110, alignment: .bottom)
        }
        .padding(16)
        .background(Color.cityCard)
        .cornerRadius(16)
    }

    private func healthSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Health")
                    .font(.game(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                Spacer()
                if profile.isHealthKitConnected {
                    Label("Apple Health", systemImage: "heart.fill")
                        .font(.game(size: 11, weight: .semibold))
                        .foregroundColor(.cityGreen)
                }
            }

            HStack(spacing: 12) {
                healthBox(value: String(format: "%.1f", profile.weightKg), unit: "kg", label: "Weight")
                healthBox(value: String(format: "%.0f", profile.heightCm), unit: "cm", label: "Height")
                healthBox(value: String(format: "%.1f", profile.bmi), unit: profile.bmiCategory, label: "BMI")
            }

            if profile.restingHeartRate != nil || profile.activeEnergyKcal != nil {
                HStack(spacing: 12) {
                    if let hr = profile.restingHeartRate {
                        healthBox(value: "\(hr)", unit: "bpm", label: "Resting HR")
                    }
                    if let energy = profile.activeEnergyKcal {
                        healthBox(value: String(format: "%.0f", energy), unit: "kcal", label: "Active Energy")
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cityCard)
        .cornerRadius(16)
    }

    private func healthBox(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.game(size: 17, weight: .heavy))
                .foregroundColor(.white)
            Text(unit)
                .font(.game(size: 11, weight: .semibold))
                .foregroundColor(.cityAccent)
            Text(label)
                .font(.game(size: 10))
                .foregroundColor(.citySubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.cityBackground)
        .cornerRadius(12)
    }

    private func dayLabel(daysAgo: Int) -> String {
        guard let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(2))
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(ProfileViewModel())
            .environmentObject(MissionViewModel())
    }
}
