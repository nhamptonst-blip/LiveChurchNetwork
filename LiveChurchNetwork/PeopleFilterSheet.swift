import SwiftUI

struct PeopleFilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedFilters: PeopleFilters
    @State private var tempFilters: PeopleFilters

    init(selectedFilters: Binding<PeopleFilters>) {
        self._selectedFilters = selectedFilters
        _tempFilters = State(initialValue: selectedFilters.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Filter People")
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
                    // Toggle filters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Discovery Options")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                        VStack(alignment: .leading, spacing: 12) {
                            FilterToggle(
                                title: "Near Me",
                                subtitle: "Find people in your area",
                                isSelected: $tempFilters.nearMe
                            )

                            FilterToggle(
                                title: "From Churches I Follow",
                                subtitle: "Members of churches you follow",
                                isSelected: $tempFilters.fromMyChurches
                            )

                            FilterToggle(
                                title: "Shared Denomination",
                                subtitle: "Same faith tradition as you",
                                isSelected: $tempFilters.sharedDenomination
                            )

                            FilterToggle(
                                title: "New Members",
                                subtitle: "Recently joined the community",
                                isSelected: $tempFilters.newMembers
                            )

                            FilterToggle(
                                title: "Faith Leaders",
                                subtitle: "Pastors and ministry leaders",
                                isSelected: $tempFilters.faithLeaders
                            )

                            FilterToggle(
                                title: "Mutual Connections",
                                subtitle: "People you have friends in common with",
                                isSelected: $tempFilters.mutualConnections
                            )

                            FilterToggle(
                                title: "Has Home Church Listed",
                                subtitle: "Members with visible church affiliation",
                                isSelected: $tempFilters.hasHomeChurch
                            )
                        }
                    }

                    // Info note
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))

                        Text("Filters help you connect with people who share your faith journey. All profiles shown have chosen to be discoverable.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(Color(red: 243/255, green: 244/255, blue: 246/255))
                    .cornerRadius(12)
                }
                .padding(20)
            }

            Divider()

            // Bottom buttons
            HStack(spacing: 12) {
                Button(action: {
                    tempFilters = PeopleFilters()
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

struct FilterToggle: View {
    let title: String
    let subtitle: String
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: { isSelected.toggle() }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))

                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 211/255, green: 213/255, blue: 219/255))
            }
        }
        .buttonStyle(.plain)
    }
}

struct PeopleFilters: Equatable {
    var nearMe: Bool = false
    var fromMyChurches: Bool = false
    var sharedDenomination: Bool = false
    var newMembers: Bool = false
    var faithLeaders: Bool = false
    var mutualConnections: Bool = false
    var hasHomeChurch: Bool = false

    var isEmpty: Bool {
        !nearMe && !fromMyChurches && !sharedDenomination && !newMembers &&
        !faithLeaders && !mutualConnections && !hasHomeChurch
    }
}

#Preview {
    PeopleFilterSheet(selectedFilters: .constant(PeopleFilters()))
}
