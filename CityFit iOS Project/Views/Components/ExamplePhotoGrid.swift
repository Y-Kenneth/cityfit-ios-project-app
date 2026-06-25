import SwiftUI

/// Shows 4 example "what counts as a good photo" placeholders in a 2x2 grid for
/// a photo mission's target object. SF Symbol placeholders for now — swap the
/// `icon` mapping below for real reference photos (e.g. an Image asset name)
/// once they're captured, without touching any call site.
struct ExamplePhotoGrid: View {
    let targetObject: String

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Example photos")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.citySubtext)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    examplePlaceholder(variant: index)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func examplePlaceholder(variant: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cityCard)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.cityAccent.opacity(0.25), lineWidth: 1)
            Image(systemName: Self.icon(for: targetObject))
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.cityAccent.opacity(0.7))
                .rotationEffect(.degrees(Double(variant) * 7 - 10))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Matches the 9 trained object classes in `VisionService`'s synonym table.
    private static func icon(for targetObject: String) -> String {
        switch targetObject.lowercased() {
        case "bottle":   return "waterbottle"
        case "bicycle":  return "bicycle"
        case "plant":    return "leaf.fill"
        case "chair":    return "chair.fill"
        case "person":   return "person.fill"
        case "trashbin": return "trash.fill"
        case "car":      return "car.fill"
        case "computer": return "laptopcomputer"
        case "cat":      return "cat.fill"
        default:         return "camera.viewfinder"
        }
    }
}

struct ExamplePhotoGrid_Previews: PreviewProvider {
    static var previews: some View {
        ExamplePhotoGrid(targetObject: "cat")
            .padding()
            .background(Color.cityBackground)
    }
}
