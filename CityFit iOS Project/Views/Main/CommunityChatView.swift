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
        .background(Color.cityBackground)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var header: some View {
        HStack {
            Label(community.name, systemImage: "bubble.left.and.bubble.right.fill")
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
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        bubble(for: message).id(message.id)
                    }
                }
                .padding(.vertical, 14)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $viewModel.draftText)
                .padding(12)
                .background(Color.cityCard)
                .cornerRadius(12)
                .foregroundColor(.white)
                .onSubmit { viewModel.send() }

            Button(action: viewModel.send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.cityAccent)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Send message")
            .disabled(viewModel.draftText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(14)
        .background(Color.cityCard)
    }

    private func bubble(for message: CommunityMessage) -> some View {
        let isMe = message.senderId == profileViewModel.profile?.id
        return HStack(alignment: .top, spacing: 8) {
            if isMe {
                Spacer(minLength: 50)
                bubbleText(message, isMe: true)
            } else {
                CharacterAvatarView(character: message.senderCharacter, size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.senderUsername)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.citySubtext)
                    bubbleText(message, isMe: false)
                }
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 16)
    }

    private func bubbleText(_ message: CommunityMessage, isMe: Bool) -> some View {
        Text(message.text)
            .font(.system(size: 14))
            .foregroundColor(isMe ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isMe ? Color.cityAccent : Color.cityCard)
            .cornerRadius(16)
    }
}

struct CommunityChatView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityChatView(community: MockData.communities[0],
                           profile: UserProfile.new(username: "Preview", character: .rabbit))
            .environmentObject(ProfileViewModel())
    }
}
