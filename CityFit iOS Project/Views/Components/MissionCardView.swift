import SwiftUI

struct MissionCardView: View {
    let mission: Mission

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cityAccent.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: mission.type.icon)
                    .font(.game(size: 20))
                    .foregroundColor(.cityAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mission.title)
                        .font(.game(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    if mission.status == .active {
                        Text("ACTIVE")
                            .font(.game(size: 9, weight: .heavy))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cityGreen)
                            .cornerRadius(4)
                    }
                }
                Text(mission.description)
                    .font(.game(size: 12))
                    .foregroundColor(.citySubtext)
                    .lineLimit(1)

                ProgressView(value: mission.progress)
                    .tint(.cityGreen)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("+\(mission.expReward)")
                    .font(.game(size: 14, weight: .bold))
                    .foregroundColor(.cityYellow)
                Text(mission.difficulty.label)
                    .font(.game(size: 10, weight: .semibold))
                    .foregroundColor(difficultyColor)
            }
        }
        .padding(14)
        .background(Color.cityCard)
        .cornerRadius(16)
        .opacity(mission.status == .completed ? 0.5 : 1)
        .overlay(alignment: .topTrailing) {
            if mission.status == .completed {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.cityGreen)
                    .padding(8)
            }
        }
    }

    private var difficultyColor: Color {
        switch mission.difficulty {
        case .easy:   return .cityGreen
        case .medium: return .cityYellow
        case .hard:   return .red
        }
    }
}

struct MissionCardView_Previews: PreviewProvider {
    static var previews: some View {
        MissionCardView(mission: MockData.missions[0])
            .padding()
            .background(Color.cityBackground)
    }
}
