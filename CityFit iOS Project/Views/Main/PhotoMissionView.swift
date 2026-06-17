import SwiftUI

struct PhotoMissionView: View {
    let mission: Mission

    @EnvironmentObject private var missionViewModel: MissionViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @EnvironmentObject private var aiViewModel: AIViewModel
    @StateObject private var cameraViewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss

    // Capture sequence stage
    private enum CaptureStage { case idle, locking, captured, complete }
    @State private var captureStage: CaptureStage = .idle
    @State private var completionEXP: Int?
    @State private var leveledUp = false

    // Ring
    @State private var progressBounce = false
    @State private var scanningRotation = 0.0

    // Capture box
    @State private var boxScale: CGFloat = 1.4
    @State private var boxOpacity: Double = 0
    @State private var cornerLineLength: CGFloat = 0
    @State private var shutterOpacity: Double = 0

    // Captured label
    @State private var labelOffset: CGFloat = 20
    @State private var labelOpacity: Double = 0

    private var currentCount: Int {
        Int(missionViewModel.activeMission?.currentValue ?? mission.currentValue)
    }
    private var targetCount: Int { Int(mission.targetValue) }
    private var target: String { mission.targetObject ?? "object" }

    var body: some View {
        ZStack {
            cameraBackground

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }

            // --- Capture box overlay (stages: locking + captured) ---
            if captureStage == .locking || captureStage == .captured {
                captureBoxOverlay
            }

            // --- Shutter flash ---
            if shutterOpacity > 0 {
                Color.white.opacity(shutterOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // --- Mission complete screen ---
            if let exp = completionEXP {
                CaptureCompleteView(
                    target: target,
                    expAwarded: exp,
                    leveledUp: leveledUp,
                    onContinue: { dismiss() }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            cameraViewModel.onObjectFound = { objectFound() }
            cameraViewModel.start(target: target)
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                scanningRotation = 360
            }
        }
        .onDisappear { cameraViewModel.stop() }
    }

    // MARK: - Camera background

    @ViewBuilder
    private var cameraBackground: some View {
        if cameraViewModel.camera.isAvailable {
            CameraPreviewView(session: cameraViewModel.camera.session)
                .ignoresSafeArea()
        } else {
            simulatorPlaceholder
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                missionViewModel.cancelActiveMission()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(mission.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text("Find: \(target.capitalized)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.cityAccent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(12)

            Spacer()

            Button {
                cameraViewModel.camera.switchCamera()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Bottom panel

    private var bottomPanel: some View {
        VStack(spacing: 16) {
            progressRing

            DetectionBannerView(state: cameraViewModel.state,
                                message: cameraViewModel.statusMessage ?? "Point camera at a \(target)")

            if cameraViewModel.state == .possible {
                Button {
                    Task {
                        await cameraViewModel.snap(
                            userID: profileViewModel.profile?.id ?? "anonymous",
                            aiViewModel: aiViewModel)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Snap!")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 14)
                    .background(Color.cityYellow)
                    .cornerRadius(16)
                    .shadow(color: Color.cityYellow.opacity(0.5), radius: 10)
                }
                .transition(.scale.combined(with: .opacity))
            }

            if cameraViewModel.state == .verifying {
                HStack(spacing: 8) {
                    ProgressView().tint(.cityAccent)
                    Text("Verifying…")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.cityAccent)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 50)
        .padding(.top, 16)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.75)],
                           startPoint: .top, endPoint: .bottom)
        )
        .animation(.easeInOut(duration: 0.25), value: cameraViewModel.state)
    }

    // MARK: - Progress ring

    private var progressRing: some View {
        let progress = targetCount > 0 ? Double(currentCount) / Double(targetCount) : 0

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 6)
                .frame(width: 90, height: 90)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [.cityAccent, .cityGreen], center: .center),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: currentCount)

            if cameraViewModel.state == .scanning {
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(Color.cityAccent.opacity(0.4), lineWidth: 3)
                    .frame(width: 104, height: 104)
                    .rotationEffect(.degrees(scanningRotation))
            }

            VStack(spacing: 0) {
                Text("\(currentCount)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .scaleEffect(progressBounce ? 1.35 : 1.0)
                Text("of \(targetCount)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.citySubtext)
            }
        }
    }

    // MARK: - Capture box overlay

    private var captureBoxOverlay: some View {
        ZStack {
            // Dim the rest of the screen slightly
            Color.black.opacity(captureStage == .captured ? 0.45 : 0.2)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 20) {
                Spacer()

                // The scanning / lock box
                ZStack {
                    // Corner brackets — grow in from zero
                    CornerBracketsView(
                        lineLength: cornerLineLength,
                        color: captureStage == .captured ? .cityGreen : .cityAccent,
                        lineWidth: 3
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(boxScale)
                    .opacity(boxOpacity)

                    // Captured label appears inside the box
                    if captureStage == .captured {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.cityGreen)
                            Text("\(target.capitalized) captured!")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        .opacity(labelOpacity)
                        .offset(y: labelOffset)
                    }
                }

                Spacer()
                Spacer()
            }
        }
    }

    // MARK: - Simulator placeholder

    private var simulatorPlaceholder: some View {
        ZStack {
            LinearGradient(colors: [.cityBackground, .cityCard],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.citySubtext)
                Text("Camera unavailable on Simulator")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.citySubtext)
                HStack(spacing: 12) {
                    Button("Clear Detection") {
                        cameraViewModel.simulateDetection(confidence: 0.92)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cityGreen)

                    Button("Uncertain") {
                        cameraViewModel.simulateDetection(confidence: 0.62)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cityYellow)
                }
            }
        }
    }

    // MARK: - Sequence

    private func objectFound() {
        // Counter bounce
        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { progressBounce = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { progressBounce = false }
        }

        missionViewModel.incrementPhotoProgress()
        let willComplete = missionViewModel.activeMission?.isComplete == true

        runCaptureSequence(willComplete: willComplete)
    }

    private func runCaptureSequence(willComplete: Bool) {
        // --- Stage 1: Box zooms in (0.0 – 0.4s) ---
        captureStage = .locking
        boxScale = 1.4
        boxOpacity = 0
        cornerLineLength = 0

        withAnimation(.easeOut(duration: 0.35)) {
            boxScale = 1.0
            boxOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4)) {
            cornerLineLength = 28
        }

        // --- Stage 2: Shutter flash at 0.4s ---
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.07)) { shutterOpacity = 0.9 }
            withAnimation(.easeOut(duration: 0.25).delay(0.07)) { shutterOpacity = 0 }
        }

        // --- Stage 3: "Captured" label slides up at 0.5s ---
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            captureStage = .captured
            labelOffset = 20
            labelOpacity = 0
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                labelOffset = 0
                labelOpacity = 1
            }
            // Box border transitions to green (handled via state)
        }

        // --- Stage 4: Hold "captured" for 1.1s, then either dismiss box or show complete ---
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if willComplete {
                let exp = missionViewModel.completeActiveMission()
                profileViewModel.addEXP(exp)
                leveledUp = profileViewModel.justLeveledUp
                profileViewModel.recordMissionCompletion(steps: 0)

                withAnimation(.easeOut(duration: 0.3)) {
                    captureStage = .complete
                    boxOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        completionEXP = exp
                    }
                }
            } else {
                // Not the last object — fade out the box and resume scanning
                withAnimation(.easeOut(duration: 0.35)) {
                    boxOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    captureStage = .idle
                }
            }
        }
    }
}

// MARK: - Corner bracket shape

private struct CornerBracketsView: View {
    let lineLength: CGFloat
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let ll = lineLength

            ZStack {
                // Top-left
                Path { p in
                    p.move(to: CGPoint(x: 0, y: ll))
                    p.addLine(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: ll, y: 0))
                }.stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Top-right
                Path { p in
                    p.move(to: CGPoint(x: w - ll, y: 0))
                    p.addLine(to: CGPoint(x: w, y: 0))
                    p.addLine(to: CGPoint(x: w, y: ll))
                }.stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Bottom-left
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h - ll))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.addLine(to: CGPoint(x: ll, y: h))
                }.stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Bottom-right
                Path { p in
                    p.move(to: CGPoint(x: w - ll, y: h))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: w, y: h - ll))
                }.stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
    }
}

// MARK: - Capture complete screen (replaces MissionCompleteView for photo missions)

private struct CaptureCompleteView: View {
    let target: String
    let expAwarded: Int
    let leveledUp: Bool
    let onContinue: () -> Void

    @State private var emojiScale: CGFloat = 0.3
    @State private var emojiOpacity: Double = 0
    @State private var titleOffset: CGFloat = 24
    @State private var titleOpacity: Double = 0
    @State private var expScale: CGFloat = 0.5
    @State private var expOpacity: Double = 0
    @State private var expGlow: Bool = false
    @State private var levelUpOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 30
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.cityBackground.opacity(0.97).ignoresSafeArea()

            VStack(spacing: 22) {
                Text("📸")
                    .font(.system(size: 72))
                    .scaleEffect(emojiScale)
                    .opacity(emojiOpacity)

                VStack(spacing: 6) {
                    Text("Mission Complete!")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                    Text("\(target.capitalized) successfully captured")
                        .font(.system(size: 14))
                        .foregroundColor(.citySubtext)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Text("+\(expAwarded) EXP")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundColor(.cityYellow)
                    .shadow(color: .cityYellow.opacity(expGlow ? 0.8 : 0.2), radius: expGlow ? 24 : 6)
                    .scaleEffect(expScale)
                    .opacity(expOpacity)

                if leveledUp {
                    Text("⬆️ LEVEL UP!")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.cityGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.cityGreen.opacity(0.15))
                        .cornerRadius(12)
                        .opacity(levelUpOpacity)
                }

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 14)
                        .background(Color.cityAccent)
                        .cornerRadius(14)
                }
                .padding(.top, 6)
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)
            }
            .padding(.horizontal, 32)
        }
        .onAppear { staggerIn() }
    }

    private func staggerIn() {
        // Emoji pops in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
            emojiScale = 1.0
            emojiOpacity = 1.0
        }
        // Title slides up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.18)) {
            titleOffset = 0
            titleOpacity = 1
        }
        // EXP bounces in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.36)) {
            expScale = 1.0
            expOpacity = 1.0
        }
        // EXP glow pulses
        withAnimation(.easeInOut(duration: 0.7).repeatCount(3, autoreverses: true).delay(0.55)) {
            expGlow = true
        }
        // Level up fades
        withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
            levelUpOpacity = 1
        }
        // Continue button slides up last
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.72)) {
            buttonOffset = 0
            buttonOpacity = 1
        }
    }
}

struct PhotoMissionView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoMissionView(mission: MockData.missions[4])
            .environmentObject(MissionViewModel())
            .environmentObject(ProfileViewModel())
            .environmentObject(AIViewModel())
    }
}
