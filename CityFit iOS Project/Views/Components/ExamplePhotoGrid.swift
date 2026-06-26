import SwiftUI

/// Shows 4 example "what counts as a good photo" reference photos in a 2x2
/// grid for a photo mission's target object. Photos are real, freely-licensed
/// images hotlinked from Wikimedia Commons (no API key, no backend dependency)
/// via `AsyncImage` — if the device is offline or a load fails, that cell
/// falls back to the SF Symbol icon instead of showing a broken image.
struct ExamplePhotoGrid: View {
    let targetObject: String

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        let urls = Self.exampleURLs(for: targetObject)

        VStack(alignment: .leading, spacing: 8) {
            Text("Example photos")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.citySubtext)
                .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    examplePhoto(url: urls.indices.contains(index) ? urls[index] : nil)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func examplePhoto(url: URL?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cityCard)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.cityAccent.opacity(0.25), lineWidth: 1)

            if let url {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholderIcon
                    }
                }
            } else {
                placeholderIcon
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var placeholderIcon: some View {
        Image(systemName: Self.icon(for: targetObject))
            .font(.system(size: 28, weight: .medium))
            .foregroundColor(.cityAccent.opacity(0.7))
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

    private static func exampleURLs(for targetObject: String) -> [URL] {
        (exampleImageURLs[targetObject.lowercased()] ?? []).compactMap(URL.init(string:))
    }

    /// 4 freely-licensed reference photos per target object, hotlinked from
    /// Wikimedia Commons at a fixed 500px thumbnail width (one of the widths
    /// Commons' thumbnail server pre-generates — arbitrary widths 400 error).
    private static let exampleImageURLs: [String: [String]] = [
        "bottle": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Bottle_of_Water.jpg/500px-Bottle_of_Water.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Camelbak_water_bottle.jpg/500px-Camelbak_water_bottle.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Metal_water_bottle.jpg/500px-Metal_water_bottle.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3d/Blue_Waters_bottle_no_label.jpg/500px-Blue_Waters_bottle_no_label.jpg"
        ],
        "bicycle": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Parked_bicycle_with_graffitied_building_facade_and_doors_in_Amsterdam.jpg/500px-Parked_bicycle_with_graffitied_building_facade_and_doors_in_Amsterdam.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Commuting_by_bicycle.jpg/500px-Commuting_by_bicycle.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/Bicycle_reflections.jpg/500px-Bicycle_reflections.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Raleigh_lady%27s_loop_frame_bicycle_1930s.jpg/500px-Raleigh_lady%27s_loop_frame_bicycle_1930s.jpg"
        ],
        "plant": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Among_the_branches_of_a_potted_jade_plant.jpg/500px-Among_the_branches_of_a_potted_jade_plant.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Peace_lily_-_2.jpg/500px-Peace_lily_-_2.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Potted_plants_in_Shilparamam_01.jpg/500px-Potted_plants_in_Shilparamam_01.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Potted_plants_in_Shilparamam_02.jpg/500px-Potted_plants_in_Shilparamam_02.jpg"
        ],
        "chair": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Office_chair_%284444288246%29.jpg/500px-Office_chair_%284444288246%29.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Buerostuhl_%28fcm%29.jpg/500px-Buerostuhl_%28fcm%29.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1c/Desk_chair_%28fauteuil_de_bureau%29_MET_174288.jpg/500px-Desk_chair_%28fauteuil_de_bureau%29_MET_174288.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Wooden_table_and_chairs_on_a_balcony_over_the_Mekong_at_sunrise_in_Don_Det_Si_Phan_Don_Laos.jpg/500px-Wooden_table_and_chairs_on_a_balcony_over_the_Mekong_at_sunrise_in_Don_Det_Si_Phan_Don_Laos.jpg"
        ],
        "person": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Silhouette_of_a_fisherman_on_his_pirogue_at_sunrise_in_Si_Phan_Don_Laos.jpg/500px-Silhouette_of_a_fisherman_on_his_pirogue_at_sunrise_in_Si_Phan_Don_Laos.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Silhouette_of_a_fisherman_standing_on_his_pirogue_at_sunset_with_orange_clouds_in_Don_Det_Si_Phan_Don_Laos.jpg/500px-Silhouette_of_a_fisherman_standing_on_his_pirogue_at_sunset_with_orange_clouds_in_Don_Det_Si_Phan_Don_Laos.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Girl_walking_dog_001.jpg/500px-Girl_walking_dog_001.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Visitor_walking_dog_leash_rialto_beach_hikers_c_bubar_march_06-2015_%2817184427098%29.jpg/500px-Visitor_walking_dog_leash_rialto_beach_hikers_c_bubar_march_06-2015_%2817184427098%29.jpg"
        ],
        "trashbin": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Trash_bin_in_Paris.jpg/500px-Trash_bin_in_Paris.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Trash_bin_in_Tumbes.jpg/500px-Trash_bin_in_Tumbes.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Trash_bin_at_Viborg_Katedralskole.jpg/500px-Trash_bin_at_Viborg_Katedralskole.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Waste_container%2C_Herzliya.jpg/500px-Waste_container%2C_Herzliya.jpg"
        ],
        "car": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/2013_Porsche_911_Carrera_4S_%28991%29_%289626546987%29.jpg/500px-2013_Porsche_911_Carrera_4S_%28991%29_%289626546987%29.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/Peugeot_206_WRC.jpg/500px-Peugeot_206_WRC.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/AvMalecon-LaHabanaCuba-04735.jpg/500px-AvMalecon-LaHabanaCuba-04735.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Abandoned_car_in_Marine_Park_%2810852p%29.jpg/500px-Abandoned_car_in_Marine_Park_%2810852p%29.jpg"
        ],
        "computer": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/Laptop_computer.jpeg/500px-Laptop_computer.jpeg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/IBM_Thinkpad_R51.jpg/500px-IBM_Thinkpad_R51.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Laptop_on_a_desk_in_shadow.jpg/500px-Laptop_on_a_desk_in_shadow.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Laptop_on_a_neat_desk_%28Unsplash%29.jpg/500px-Laptop_on_a_neat_desk_%28Unsplash%29.jpg"
        ],
        "cat": [
            "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Felis_catus-cat_on_snow.jpg/500px-Felis_catus-cat_on_snow.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Cat_November_2010-1a.jpg/500px-Cat_November_2010-1a.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Sleeping_cat_on_her_back.jpg/500px-Sleeping_cat_on_her_back.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/20231125_housecat_south_meadows_PD100306.jpg/500px-20231125_housecat_south_meadows_PD100306.jpg"
        ]
    ]
}

struct ExamplePhotoGrid_Previews: PreviewProvider {
    static var previews: some View {
        ExamplePhotoGrid(targetObject: "cat")
            .padding()
            .background(Color.cityBackground)
    }
}
