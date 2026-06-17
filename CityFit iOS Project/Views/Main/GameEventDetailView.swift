import SwiftUI

struct GameEventDetailView: View {
    let event: GameEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header band
                ZStack {
                    event.eventType.color.opacity(0.15)
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(event.eventType.color.opacity(0.25))
                                .frame(width: 80, height: 80)
                            Circle()
                                .fill(event.eventType.color)
                                .frame(width: 56, height: 56)
                            Image(systemName: event.eventType.icon)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.black)
                        }
                        Text(event.title)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)
                        Text(eventTypeLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(event.eventType.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(event.eventType.color.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 32)
                }

                // Details
                VStack(spacing: 16) {
                    infoRow(icon: "text.alignleft", label: "Description", value: event.description)
                    Divider().background(Color.cityCard)
                    infoRow(icon: "bolt.fill", label: "EXP Reward", value: "+\(event.expReward) EXP")
                    Divider().background(Color.cityCard)
                    infoRow(icon: "mappin.circle.fill", label: "Location", value: String(format: "%.4f, %.4f", event.coordinate.latitude, event.coordinate.longitude))
                }
                .padding(24)
                .background(Color.cityCard)
                .cornerRadius(20)
                .padding(16)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cityAccent)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var eventTypeLabel: String {
        switch event.eventType {
        case .run:      return "Running Event"
        case .wellness: return "Wellness Event"
        case .walk:     return "Walking Event"
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(event.eventType.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.citySubtext)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            Spacer()
        }
    }
}

struct GameEventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        GameEventDetailView(event: MockData.gameEvents[0])
    }
}
