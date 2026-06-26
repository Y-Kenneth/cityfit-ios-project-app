import SwiftUI

/// Gender toggle + weight/height steppers. Shared by CharacterSelectView's
/// onboarding step and EditProfileView's manual-edit mode — stepper-only
/// input (no text field) so a value can never end up invalid (empty, non-
/// numeric, decimal-malformed) the way free typing would allow.
struct HealthInfoFormView: View {
    @Binding var gender: Gender
    @Binding var weightKg: Double
    @Binding var heightCm: Double

    private let weightRange: ClosedRange<Double> = 30...200
    private let heightRange: ClosedRange<Double> = 100...220

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Gender")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.citySubtext)
                HStack(spacing: 10) {
                    ForEach(Gender.allCases, id: \.self) { option in
                        genderButton(option)
                    }
                }
            }

            stepperRow(title: "Weight", value: $weightKg, unit: "kg", step: 0.5, range: weightRange, decimals: 1)
            stepperRow(title: "Height", value: $heightCm, unit: "cm", step: 1, range: heightRange, decimals: 0)
        }
    }

    private func genderButton(_ option: Gender) -> some View {
        Button {
            gender = option
        } label: {
            Text(option.displayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(gender == option ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(gender == option ? Color.cityAccent : Color.cityCard)
                .cornerRadius(12)
        }
    }

    private func stepperRow(title: String, value: Binding<Double>, unit: String, step: Double,
                             range: ClosedRange<Double>, decimals: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.citySubtext)
            HStack {
                stepButton(systemName: "minus") {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
                }
                Spacer()
                Text("\(value.wrappedValue, specifier: decimals == 0 ? "%.0f" : "%.1f") \(unit)")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(minWidth: 90)
                Spacer()
                stepButton(systemName: "plus") {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(Color.cityCard)
            .cornerRadius(14)
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 36, height: 36)
                .background(Color.cityAccent)
                .clipShape(Circle())
        }
    }
}

struct HealthInfoFormView_Previews: PreviewProvider {
    static var previews: some View {
        HealthInfoFormView(gender: .constant(.male), weightKg: .constant(70), heightCm: .constant(170))
            .padding()
            .background(Color.cityBackground)
    }
}
