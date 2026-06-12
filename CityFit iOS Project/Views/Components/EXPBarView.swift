import SwiftUI

struct EXPBarView: View {
    let level: Int
    let currentEXP: Int

    var body: some View {
        HStack(spacing: 10) {
            Text("Lv.\(level)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.cityGreen)
                        .frame(width: geo.size.width * EXPCalculator.progress(currentEXP: currentEXP))
                        .animation(.easeOut(duration: 0.6), value: currentEXP)
                }
            }
            .frame(height: 10)

            Text("\(currentEXP) EXP")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.cityAccent)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(level), \(currentEXP) experience points")
    }
}

struct EXPBarView_Previews: PreviewProvider {
    static var previews: some View {
        EXPBarView(level: 5, currentEXP: 1340)
            .padding()
            .background(Color.cityBackground)
    }
}
