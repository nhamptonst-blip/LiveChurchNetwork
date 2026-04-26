import SwiftUI

struct DirectoryControlBar: View {
    @Binding var selectedSort: String
    @Binding var viewDensity: String
    let onFiltersTap: () -> Void
    let sortOptions: [String]
    @State private var showSortMenu = false

    var body: some View {
        HStack(spacing: 8) {
            // Sort Button
            Button(action: {
                showSortMenu.toggle()
                HapticEngine.selection()
            }) {
                ControlPillLabel(label: selectedSort, isActive: false)
            }
            .sheet(isPresented: $showSortMenu) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Sort By")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                    Divider()

                    VStack(spacing: 0) {
                        ForEach(sortOptions, id: \.self) { option in
                            Button(action: {
                                selectedSort = option
                                HapticEngine.selection()
                                showSortMenu = false
                            }) {
                                HStack {
                                    Text(option)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
                                    Spacer()
                                    if selectedSort == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 31/255, green: 60/255, blue: 136/255))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 48)
                                .contentShape(Rectangle())
                            }

                            if option != sortOptions.last {
                                Divider().padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer()
                }
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
            }

            // Filters Button
            Button(action: {
                HapticEngine.selection()
                onFiltersTap()
            }) {
                ControlPillLabel(label: "Filters", isActive: false)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct ControlPillLabel: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(isActive ? Color.white : Color(red: 55/255, green: 65/255, blue: 81/255))
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isActive ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 999))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Color(red: 229/255, green: 231/255, blue: 235/255), lineWidth: 1)
            )
    }
}

#Preview {
    VStack(spacing: 12) {
        DirectoryControlBar(
            selectedSort: .constant("Recommended"),
            viewDensity: .constant("Comfortable"),
            onFiltersTap: { },
            sortOptions: ["Recommended", "Most Followed", "Recently Added", "A–Z", "Live Now"]
        )
        Spacer()
    }
    .padding(20)
    .background(Color(red: 250/255, green: 249/255, blue: 246/255))
}
