import SwiftUI

struct MissionCompleteView: View {
    let expAwarded: Int
    let leveledUp: Bool
    let onContinue: () -> Void

    @State private var celebrate = false

    var body: some View {
        VStack(spacing: 18) {
            Text("🎉")
                .font(.system(size: 72))
                .scaleEffect(celebrate ? 1.15 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: celebrate)

            Text("Mission Complete!")
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.white)

            Text("+\(expAwarded) EXP")
                .font(.system(size: 36, weight: .heavy))
                .foregroundColor(.cityYellow)
                .shadow(color: .cityYellow.opacity(0.5), radius: celebrate ? 16 : 4)

            if leveledUp {
                Text("⬆️ LEVEL UP!")
                    .font(.system(size: 20, weight: .heavy))
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
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 14)
                    .background(Color.cityAccent)
                    .cornerRadius(14)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cityBackground.opacity(0.97))
        .ignoresSafeArea()
        .onAppear { celebrate = true }
    }
}

struct MissionCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        MissionCompleteView(expAwarded: 200, leveledUp: true) {}
    }
}
