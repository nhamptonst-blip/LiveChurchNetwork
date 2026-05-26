import SwiftUI

/// Smart Recommendations card — shows the visibility score, tier badge, and
/// the top 5 unfinished factors weighted by impact. 1:1 visual port of web's
/// <ChurchVisibilityScore/>.
struct VisibilityScoreCard: View {
    let result: VisibilityResult
    /// Called when a recommendation row is tapped — the host should route to
    /// the appropriate Edit Profile / Create Post / Create Event sheet.
    let onTapFactor: (VisibilityFactor) -> Void

    var body: some View {
        if result.score == 100 {
            completedCard
        } else {
            scoredCard
        }
    }

    // MARK: - Completed (100) state

    private var completedCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.green).frame(width: 40, height: 40)
                Text("✓")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Smart Recommendations")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                Text("Your profile is 100% set up. Keep posting weekly to stay in members' feeds.")
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.10), Color.white, Color.lcGoldLight.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Scored state

    private var scoredCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(Color.lcBorder)
            recommendations
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lcBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Recommendations")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.lcText)
                Text("Personalized actions to grow your church's reach.")
                    .font(.system(size: 12))
                    .foregroundColor(.lcText3)
                    .lineLimit(2)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 4) {
                tierPill
                Text("\(result.score)/100 visibility")
                    .font(.system(size: 10))
                    .foregroundColor(.lcText3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var tierPill: some View {
        Text(result.tier.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.6)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tierBackground)
            .foregroundColor(tierForeground)
            .clipShape(Capsule())
    }

    private var tierBackground: Color {
        switch result.tier {
        case .excellent:      return Color.green.opacity(0.15)
        case .strong:         return Color.lcTeal.opacity(0.15)
        case .building:       return Color.lcNavy.opacity(0.10)
        case .gettingStarted: return Color.lcGoldLight
        }
    }

    private var tierForeground: Color {
        switch result.tier {
        case .excellent:      return Color.green
        case .strong:         return Color.lcTeal
        case .building:       return Color.lcNavy
        case .gettingStarted: return Color.lcGold
        }
    }

    private var recommendations: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(result.remaining.prefix(5))) { factor in
                Button(action: { onTapFactor(factor) }) {
                    HStack(alignment: .top, spacing: 12) {
                        weightPill(factor.weight)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(factor.label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.lcText)
                                Text("→")
                                    .font(.system(size: 13))
                                    .foregroundColor(.lcText3)
                            }
                            Text(factor.tip)
                                .font(.system(size: 12))
                                .foregroundColor(.lcText3)
                                .lineSpacing(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func weightPill(_ weight: Int) -> some View {
        ZStack {
            Circle()
                .fill(Color.lcGoldLight)
                .frame(width: 24, height: 24)
            Circle()
                .stroke(Color.lcGold, lineWidth: 1)
                .frame(width: 24, height: 24)
            Text("+\(weight)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.lcGold)
        }
    }
}
