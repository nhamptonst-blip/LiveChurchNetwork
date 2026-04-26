import SwiftUI

struct ChurchFilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFilters: ChurchFilters
    @State private var tempFilters: ChurchFilters

    init(selectedFilters: Binding<ChurchFilters>) {
        self._selectedFilters = selectedFilters
        _tempFilters = State(initialValue: selectedFilters.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Filter Churches")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                    }
                }
                .padding(20)
            }
            .background(Color.white)

            Divider()

            // Filters content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Location
                    ChurchFilterCheckboxSection(
                        title: "Location",
                        options: ["Near Me", "Anywhere"],
                        selectedOptions: $tempFilters.location
                    )

                    // Denomination
                    ChurchFilterCheckboxSection(
                        title: "Denomination",
                        options: ["Baptist", "Catholic", "Pentecostal", "Methodist", "Lutheran", "Presbyterian"],
                        selectedOptions: $tempFilters.denominations
                    )

                    // Service Availability
                    ChurchFilterCheckboxSection(
                        title: "Service Availability",
                        options: ["Sunday", "Saturday", "Weekday", "Online"],
                        selectedOptions: $tempFilters.serviceAvailability
                    )

                    // Language
                    ChurchFilterCheckboxSection(
                        title: "Language",
                        options: ["English", "Spanish", "Mandarin", "Korean", "Vietnamese"],
                        selectedOptions: $tempFilters.languages
                    )

                    // Ministries
                    ChurchFilterCheckboxSection(
                        title: "Ministries",
                        options: ["Youth", "College", "Singles", "Families", "Prayer", "Music"],
                        selectedOptions: $tempFilters.ministries
                    )

                    // Worship Style
                    ChurchFilterCheckboxSection(
                        title: "Worship Style",
                        options: ["Traditional", "Contemporary", "Gospel", "Charismatic"],
                        selectedOptions: $tempFilters.worshipStyles
                    )
                }
                .padding(20)
            }

            Divider()

            // Bottom buttons
            HStack(spacing: 12) {
                Button(action: {
                    tempFilters = ChurchFilters()
                }) {
                    Text("Clear")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 243/255, green: 244/255, blue: 246/255))
                        .cornerRadius(16)
                }

                Button(action: {
                    selectedFilters = tempFilters
                    dismiss()
                }) {
                    Text("Show Results")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .cornerRadius(16)
                }
            }
            .padding(20)
        }
        .background(Color.white)
    }
}

struct ChurchFilterCheckboxSection: View {
    let title: String
    let options: [String]
    @Binding var selectedOptions: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        if selectedOptions.contains(option) {
                            selectedOptions.remove(option)
                        } else {
                            selectedOptions.insert(option)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: selectedOptions.contains(option) ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(selectedOptions.contains(option) ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 211/255, green: 213/255, blue: 219/255))

                            Text(option)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ChurchFilters: Equatable {
    var location: Set<String> = []
    var denominations: Set<String> = []
    var serviceAvailability: Set<String> = []
    var languages: Set<String> = []
    var ministries: Set<String> = []
    var worshipStyles: Set<String> = []

    var isEmpty: Bool {
        location.isEmpty && denominations.isEmpty && serviceAvailability.isEmpty &&
        languages.isEmpty && ministries.isEmpty && worshipStyles.isEmpty
    }
}

#Preview {
    ChurchFilterSheet(selectedFilters: .constant(ChurchFilters()))
}
