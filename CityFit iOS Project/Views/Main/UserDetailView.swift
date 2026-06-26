import SwiftUI

/// Opened by tapping a row on the Ranks tab — shows that user's health
/// stats (weight, height, BMI, gender, resting HR, active energy) alongside
/// their EXP/level, so the leaderboard is more than rank decoration.
struct UserDetailView: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Capsule()
                        .fill(Color.citySubtext.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    header

                    HStack(spacing: 12) {
                        statBox(value: "\(entry.level)", label: "Level", icon: "star.fill")
                        statBox(value: "\(entry.exp)", label: "EXP", icon: "bolt.fill")
                        statBox(value: "\(entry.streak)🔥", label: "Streak", icon: "flame.fill")
                    }

                    healthSection

                    Text("\(entry.totalSteps) total steps logged")
                        .font(.system(size: 12))
                        .foregroundColor(.citySubtext)
                }
                .padding(20)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        HStack(spacing: 14) {
            CharacterAvatarView(character: entry.character, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    if isCurrentUser {
                        Text("YOU")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cityAccent)
                            .cornerRadius(6)
                    }
                }
                Text("Rank \(rankLabel) · \(entry.character.displayName)")
                    .font(.system(size: 13))
                    .foregroundColor(.citySubtext)
            }
        }
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Health")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                Spacer()
                Text(entry.gender.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.citySubtext)
            }

            HStack(spacing: 12) {
                healthBox(value: String(format: "%.1f", entry.weightKg), unit: "kg", label: "Weight")
                healthBox(value: String(format: "%.0f", entry.heightCm), unit: "cm", label: "Height")
                healthBox(value: String(format: "%.1f", entry.bmi), unit: entry.bmiCategory, label: "BMI")
            }

            if entry.restingHeartRate != nil || entry.activeEnergyKcal != nil {
                HStack(spacing: 12) {
                    if let hr = entry.restingHeartRate {
                        healthBox(value: "\(hr)", unit: "bpm", label: "Resting HR")
                    }
                    if let energy = entry.activeEnergyKcal {
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
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(.white)
            Text(unit)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cityAccent)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.citySubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.cityBackground)
        .cornerRadius(12)
    }

    private func statBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.cityAccent)
            Text(value)
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.citySubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cityCard)
        .cornerRadius(14)
    }

    private var rankLabel: String {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(entry.rank)"
        }
    }
}

struct UserDetailView_Previews: PreviewProvider {
    static var previews: some View {
        UserDetailView(entry: MockData.leaderboard[0], isCurrentUser: false)
    }
}
