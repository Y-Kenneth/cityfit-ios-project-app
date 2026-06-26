import SwiftUI

struct CommunityChatView: View {
    let community: Community
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @StateObject private var viewModel: CommunityChatViewModel
    @Environment(\.dismiss) private var dismiss

    init(community: Community, profile: UserProfile) {
        self.community = community
        _viewModel = StateObject(wrappedValue: CommunityChatViewModel(
            communityId: community.id,
            senderId: profile.id,
            senderUsername: profile.username,
            senderCharacter: profile.character))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            messagesList
            inputBar
        }
        .background(Color(hex: "#E5E5EA"))
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var header: some View {
        ZStack {
            Text(community.name)
                .font(.game(size: 17, weight: .semibold))
                .foregroundColor(.black)
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.game(size: 14, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                }
                .accessibilityLabel("Close chat")
            }
        }
        .padding(16)
        .background(Color(hex: "#EDEDED"))
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        let previous = index > 0 ? viewModel.messages[index - 1] : nil
                        if shouldShowTimeDivider(before: message, previous: previous) {
                            timeDivider(for: message.sentAt)
                        }
                        bubble(for: message, showSenderName: previous?.senderId != message.senderId)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 14)
            }
            .background(Color(hex: "#E5E5EA"))
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    /// WeChat shows a centered timestamp divider above the first message of a
    /// cluster, but only when enough time has passed since the previous one —
    /// otherwise every message would get its own divider.
    private func shouldShowTimeDivider(before message: CommunityMessage, previous: CommunityMessage?) -> Bool {
        guard let previous else { return true }
        return message.sentAt.timeIntervalSince(previous.sentAt) > 60 * 10
    }

    private func timeDivider(for date: Date) -> some View {
        Text(date.formatted(.dateTime.month().day().hour().minute()))
            .font(.game(size: 11))
            .foregroundColor(.black.opacity(0.4))
            .padding(.vertical, 12)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $viewModel.draftText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(6)
                .foregroundColor(.black)
                .onSubmit { viewModel.send() }

            Button("Send", action: viewModel.send)
                .font(.game(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(viewModel.draftText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color.gray.opacity(0.5) : Color(hex: "#07C160"))
                .cornerRadius(6)
                .accessibilityLabel("Send message")
                .disabled(viewModel.draftText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(hex: "#F7F7F7"))
    }

    private func bubble(for message: CommunityMessage, showSenderName: Bool) -> some View {
        let isMe = message.senderId == profileViewModel.profile?.id
        return HStack(alignment: .top, spacing: 8) {
            if isMe {
                Spacer(minLength: 50)
                bubbleText(message, isMe: true)
                squareAvatar(message.senderCharacter)
            } else {
                squareAvatar(message.senderCharacter)
                VStack(alignment: .leading, spacing: 3) {
                    if showSenderName {
                        Text(message.senderUsername)
                            .font(.game(size: 12))
                            .foregroundColor(.black.opacity(0.45))
                    }
                    bubbleText(message, isMe: false)
                }
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    private func squareAvatar(_ character: CharacterType) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cityAccent.opacity(0.15))
            Text(character.emoji)
                .font(.game(size: 19))
        }
        .frame(width: 36, height: 36)
        .accessibilityLabel("\(character.displayName) character")
    }

    private func bubbleText(_ message: CommunityMessage, isMe: Bool) -> some View {
        Text(message.text)
            .font(.game(size: 16))
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isMe ? Color(hex: "#95EC69") : Color.white)
            .cornerRadius(6)
    }
}

struct CommunityChatView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityChatView(community: MockData.communities[0],
                           profile: UserProfile.new(username: "Preview", character: .rabbit))
            .environmentObject(ProfileViewModel())
    }
}
