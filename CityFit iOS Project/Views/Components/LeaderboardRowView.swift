import SwiftUI

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(rankLabel)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(rankColor)
                .frame(width: 36)

            CharacterAvatarView(character: entry.character, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.system(size: 15, weight: isCurrentUser ? .heavy : .semibold))
                    .foregroundColor(isCurrentUser ? .cityAccent : .white)
                Text("Level \(entry.level)")
                    .font(.system(size: 12))
                    .foregroundColor(.citySubtext)
            }

            Spacer()

            Text("\(entry.exp) EXP")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.cityYellow)
        }
        .padding(12)
        .background(isCurrentUser ? Color.cityAccent.opacity(0.12) : Color.cityCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isCurrentUser ? Color.cityAccent : .clear, lineWidth: 1.5)
        )
    }

    private var rankLabel: String {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(entry.rank)"
        }
    }

    private var rankColor: Color {
        entry.rank <= 3 ? .cityYellow : .citySubtext
    }
}

struct LeaderboardRowView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardRowView(entry: MockData.leaderboard[4], isCurrentUser: true)
            .padding()
            .background(Color.cityBackground)
    }
}
