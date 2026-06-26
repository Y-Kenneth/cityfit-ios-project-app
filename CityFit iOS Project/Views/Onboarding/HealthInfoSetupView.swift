import SwiftUI

/// Second onboarding step, after character selection: collects gender/weight/
/// height via stepper-only input (HealthInfoFormView) so the new profile has
/// real values instead of just defaults — used for the BMI shown on Profile
/// and for the Health-data-on-Ranks feature. Connecting to Apple Health
/// happens later from EditProfileView, once the profile (and its uid) exists.
struct HealthInfoSetupView: View {
    let username: String
    let character: CharacterType

    @State private var gender: Gender = .male
    @State private var weightKg: Double = 70
    @State private var heightCm: Double = 170
    @State private var showLoading = false

    var body: some View {
        ZStack {
            Color.cityBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("A few health basics")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                    Text("Used to calculate your BMI and personalize EXP. You can connect Apple Health or edit this anytime later.")
                        .font(.system(size: 13))
                        .foregroundColor(.citySubtext)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)
                .padding(.horizontal, 12)

                ScrollView {
                    HealthInfoFormView(gender: $gender, weightKg: $weightKg, heightCm: $heightCm)
                }

                Button {
                    showLoading = true
                } label: {
                    Text("Start My Journey")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cityAccent)
                        .cornerRadius(14)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Health Info")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showLoading) {
            OnboardingLoadingView(username: username, character: character,
                                  gender: gender, weightKg: weightKg, heightCm: heightCm)
        }
    }
}

struct HealthInfoSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HealthInfoSetupView(username: "Kenneth", character: .ninja)
        }
    }
}
