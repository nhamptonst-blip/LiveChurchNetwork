import SwiftUI

struct ViewToggle: View {
    @Binding var selectedView: ViewMode

    enum ViewMode {
        case grid
        case list
        case map
    }

    var body: some View {
        HStack(spacing: 4) {
            // Grid button
            Button(action: { selectedView = .grid }) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedView == .grid ? Color.white : Color.clear)
                    .foregroundColor(selectedView == .grid ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 107/255, green: 114/255, blue: 128/255))
                    .shadow(color: selectedView == .grid ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
            }

            // List button
            Button(action: { selectedView = .list }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedView == .list ? Color.white : Color.clear)
                    .foregroundColor(selectedView == .list ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 107/255, green: 114/255, blue: 128/255))
                    .shadow(color: selectedView == .list ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
            }

            // Map button
            Button(action: { selectedView = .map }) {
                Image(systemName: "map")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedView == .map ? Color.white : Color.clear)
                    .foregroundColor(selectedView == .map ? Color(red: 31/255, green: 60/255, blue: 136/255) : Color(red: 107/255, green: 114/255, blue: 128/255))
                    .shadow(color: selectedView == .map ? Color.black.opacity(0.08) : Color.clear, radius: 2, x: 0, y: 1)
            }
        }
        .frame(height: 40)
        .background(Color(red: 243/255, green: 244/255, blue: 246/255))
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }
}

#Preview {
    @State var view: ViewToggle.ViewMode = .grid
    return ViewToggle(selectedView: $view)
}
