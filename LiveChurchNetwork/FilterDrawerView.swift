import SwiftUI

struct FilterDrawerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var activeFilters: Set<DiscoverViewModel.DiscoverFilter>
    var vm: DiscoverViewModel

    @State private var selectedDenominations: Set<String> = []
    @State private var selectedServices: Set<String> = []
    @State private var selectedLanguages: Set<String> = []
    @State private var selectedMinistries: Set<String> = []
    @State private var selectedWorshipStyles: Set<String> = []
    @State private var nearMe = false
    @State private var selectedCity = ""
    @State private var selectedState = ""
    @State private var distanceRadius = 25.0

    private let denominationOptions = [
        "Non-Denominational", "Baptist", "Catholic", "Pentecostal",
        "Methodist", "Lutheran", "Presbyterian", "Orthodox", "Anglican", "Evangelical", "Other"
    ]

    private let serviceOptions = [
        "Live now", "Has livestream", "Has sermon archive", "In-person services", "Online only"
    ]

    private let languageOptions = [
        "English", "Spanish", "Korean", "Armenian", "Chinese", "Tagalog", "Other"
    ]

    private let ministryOptions = [
        "Young Adults", "Youth", "Families", "Men", "Women", "Recovery", "Bible Study", "Missions", "Worship"
    ]

    private let worshipStyleOptions = [
        "Contemporary", "Traditional", "Gospel", "Charismatic", "Liturgical"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 0) {
                Text("Filter Churches")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            .background(Color.white)
            .border(Color(red: 229/255, green: 231/255, blue: 235/255), width: 1)

            // Filter Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Location Section
                    FilterSection(title: "Location") {
                        Toggle("Near me", isOn: $nearMe)
                            .tint(Color(red: 31/255, green: 60/255, blue: 136/255))

                        if nearMe {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Distance radius: \(Int(distanceRadius)) mi")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                                Slider(value: $distanceRadius, in: 5...100, step: 5)
                                    .tint(Color(red: 31/255, green: 60/255, blue: 136/255))
                            }
                        }
                    }

                    // Denomination Section
                    FilterSection(title: "Denomination") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(denominationOptions, id: \.self) { option in
                                Toggle(option, isOn: Binding(
                                    get: { selectedDenominations.contains(option) },
                                    set: { if $0 { selectedDenominations.insert(option) } else { selectedDenominations.remove(option) } }
                                ))
                                .tint(Color(red: 31/255, green: 60/255, blue: 136/255))
                            }
                        }
                    }

                    // Service Availability Section
                    FilterSection(title: "Service Availability") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(serviceOptions, id: \.self) { option in
                                Toggle(option, isOn: Binding(
                                    get: { selectedServices.contains(option) },
                                    set: { if $0 { selectedServices.insert(option) } else { selectedServices.remove(option) } }
                                ))
                                .tint(Color(red: 31/255, green: 60/255, blue: 136/255))
                            }
                        }
                    }

                    // Language Section
                    FilterSection(title: "Language") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(languageOptions, id: \.self) { option in
                                Toggle(option, isOn: Binding(
                                    get: { selectedLanguages.contains(option) },
                                    set: { if $0 { selectedLanguages.insert(option) } else { selectedLanguages.remove(option) } }
                                ))
                                .tint(Color(red: 31/255, green: 60/255, blue: 136/255))
                            }
                        }
                    }

                    // Ministries Section
                    FilterSection(title: "Ministries") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(ministryOptions, id: \.self) { option in
                                Toggle(option, isOn: Binding(
                                    get: { selectedMinistries.contains(option) },
                                    set: { if $0 { selectedMinistries.insert(option) } else { selectedMinistries.remove(option) } }
                                ))
                                .tint(Color(red: 31/255, green: 60/255, blue: 136/255))
                            }
                        }
                    }

                    // Worship Style Section
                    FilterSection(title: "Worship Style") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(worshipStyleOptions, id: \.self) { option in
                                Toggle(option, isOn: Binding(
                                    get: { selectedWorshipStyles.contains(option) },
                                    set: { if $0 { selectedWorshipStyles.insert(option) } else { selectedWorshipStyles.remove(option) } }
                                ))
                                .tint(Color(red: 31/255, green: 60/255, blue: 136/255))
                            }
                        }
                    }

                    Spacer()
                        .frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }

            // Sticky Buttons
            VStack(spacing: 12) {
                Button {
                    clearFilters()
                } label: {
                    Text("Clear")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .border(Color(red: 31/255, green: 60/255, blue: 136/255), width: 1)
                        .cornerRadius(16)
                }

                Button {
                    applyFilters()
                } label: {
                    Text("Show Results")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 31/255, green: 60/255, blue: 136/255))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .border(Color(red: 229/255, green: 231/255, blue: 235/255), width: 1)
        }
    }

    private func clearFilters() {
        selectedDenominations.removeAll()
        selectedServices.removeAll()
        selectedLanguages.removeAll()
        selectedMinistries.removeAll()
        selectedWorshipStyles.removeAll()
        nearMe = false
        distanceRadius = 25.0
    }

    private func applyFilters() {
        // Clear existing filters
        activeFilters.removeAll()

        // Add selected denomination filters
        for denom in selectedDenominations {
            activeFilters.insert(.denomination(denom))
        }

        // Add nearMe filter if selected
        if nearMe {
            activeFilters.insert(.nearMe)
        }

        // Reload churches with applied filters
        Task {
            await vm.reloadChurchesWithFilters()
        }

        dismiss()
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

            content()
        }
    }
}

#Preview {
    FilterDrawerView(activeFilters: .constant(Set()), vm: DiscoverViewModel())
        .presentationDetents([.fraction(0.85)])
        .presentationDragIndicator(.visible)
}
