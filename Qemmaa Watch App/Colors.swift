import SwiftUI

// Colors: Xcode already creates Color.qBackground, Color.qGold, ... from the names in Assets.xcassets
// ("Generate Asset Symbol Extensions"). So there is NO manual `extension Color` here.
// Use them in views like this:  .foregroundStyle(Color.qGold)
//
// Needs iOS 17 / watchOS 10 or newer. If your deployment target is older, see README.

// MARK: - Palette page (preview only, to see every color in one place)
struct PalettePage: View {
    private let items: [(name: String, hex: String, use: String, color: Color)] = [
        ("QBackground", "#0E0B09", "App background", .qBackground),
        ("QCard", "#1A1411", "Cards and rows", .qCard),
        ("QIconCircle", "#2A211A", "Icon circles, buttons on cards", .qIconCircle),
        ("QGold", "#D4A86A", "Main accent, primary buttons", .qGold),
        ("QMuted", "#A99B8C", "Secondary text", .qMuted),
        ("QText", "#F3E9DA", "Main text", .qText),
        ("QDot", "#4A4038", "Inactive dots, locked stops", .qDot),
        ("QViolet", "#B79AD6", "XP bar and current position", .qViolet),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(items, id: \.name) { item in
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(item.color)
                            .frame(width: 64, height: 64)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.qDot, lineWidth: 1))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.headline).foregroundStyle(Color.qText)
                            Text(item.hex).font(.subheadline.monospaced()).foregroundStyle(Color.qGold)
                            Text(item.use).font(.footnote).foregroundStyle(Color.qMuted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(Color.qCard, in: RoundedRectangle(cornerRadius: 24))
                }
            }
            .padding(24)
        }
        .background(Color.qBackground.ignoresSafeArea())
    }
}

#Preview {
    PalettePage()
}
