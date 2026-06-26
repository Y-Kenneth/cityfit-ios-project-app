import SwiftUI

struct MissionCompleteView: View {
    let expAwarded: Int
    let leveledUp: Bool
    let onContinue: () -> Void

    @State private var celebrate = false

    var body: some View {
        VStack(spacing: 18) {
            Text("🎉")
                .font(.game(size: 72))
                .scaleEffect(celebrate ? 1.15 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: celebrate)

            Text("Mission Complete!")
                .font(.gameTitle(size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            Text("+\(expAwarded) EXP")
                .font(.gameTitle(size: 24))
                .foregroundColor(.cityYellow)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .shadow(color: .cityYellow.opacity(0.5), radius: celebrate ? 16 : 4)

            if leveledUp {
                Text("⬆️ LEVEL UP!")
                    .font(.gameTitle(size: 13))
                    .foregroundColor(.cityGreen)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.cityGreen.opacity(0.15))
                    .cornerRadius(12)
            }

            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(.game(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 14)
                    .background(Color.cityAccent)
                    .cornerRadius(14)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackgroundView())
        .ignoresSafeArea()
        .onAppear { celebrate = true }
    }
}

struct MissionCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        MissionCompleteView(expAwarded: 200, leveledUp: true) {}
    }
}
