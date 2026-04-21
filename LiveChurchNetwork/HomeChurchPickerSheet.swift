import SwiftUI

struct HomeChurchPickerSheet: View {
    @Binding var selectedSlug: String?
    @Binding var customName: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select Your Home Church")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lcText)
                        .padding(.horizontal, 16)

                    ForEach(appState.approvedChurches, id: \.id) { church in
                        Button {
                            selectedSlug = (church.churchName ?? "").lowercased().replacingOccurrences(of: " ", with: "-")
                            customName = church.churchName
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(church.churchName ?? "Unknown")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.lcText)
                                    if let denom = church.denomination {
                                        Text(denom)
                                            .font(.system(size: 12))
                                            .foregroundColor(.lcText3)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .border(Color.lcBorder, width: 1)
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer()
                }
                .padding(.vertical, 16)
            }
            .background(Color.lcCream)
            .navigationTitle("Select Church")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
