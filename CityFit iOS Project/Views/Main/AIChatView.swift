import SwiftUI

/// Floating AI coach chat sheet (CrewAI Chat Crew via /chat endpoint).
struct AIChatView: View {
    @EnvironmentObject private var aiViewModel: AIViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var missionViewModel: MissionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var input = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("AI Coach", systemImage: "bubble.left.fill")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.cityAccent)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.citySubtext)
                }
                .accessibilityLabel("Close chat")
            }
            .padding(16)
            .background(Color.cityCard)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(aiViewModel.chatMessages) { message in
                            bubble(for: message)
                                .id(message.id)
                        }
                        if aiViewModel.isChatLoading {
                            HStack {
                                ProgressView().tint(.cityAccent)
                                Text("Coach is thinking…")
                                    .font(.system(size: 12))
                                    .foregroundColor(.citySubtext)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 14)
                }
                .onChange(of: aiViewModel.chatMessages.count) { _ in
                    if let last = aiViewModel.chatMessages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            // Input bar
            HStack(spacing: 10) {
                TextField("Ask your coach…", text: $input)
                    .padding(12)
                    .background(Color.cityCard)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .onSubmit(send)

                Button(action: send) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(12)
                        .background(Color.cityAccent)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Send message")
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || aiViewModel.isChatLoading)
            }
            .padding(14)
            .background(Color.cityCard)
        }
        .background(Color.cityBackground)
    }

    private func send() {
        let text = input
        input = ""
        Task {
            await aiViewModel.sendChat(
                text,
                profile: profileViewModel.profile,
                activeMission: missionViewModel.activeMission,
                stepsToday: profileViewModel.profile?.weeklySteps.first ?? 0,
                missionsCompleted: profileViewModel.profile?.missionsCompleted ?? 0)
        }
    }

    private func bubble(for message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 50) }
            Text(message.text)
                .font(.system(size: 14))
                .foregroundColor(message.role == .user ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.role == .user ? Color.cityAccent : Color.cityCard)
                .cornerRadius(16)
            if message.role == .assistant { Spacer(minLength: 50) }
        }
        .padding(.horizontal, 16)
    }
}

struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
            .environmentObject(AIViewModel())
            .environmentObject(ProfileViewModel())
            .environmentObject(MissionViewModel())
    }
}
