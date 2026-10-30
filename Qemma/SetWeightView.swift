import SwiftUI

// MARK: - Palette (private to this file to avoid name clashes)

private enum WeightPalette {
    static let background = Color(red: 0.067, green: 0.055, blue: 0.043)
    static let gold = Color(red: 0.831, green: 0.659, blue: 0.416)
    static let title = Color(red: 0.96, green: 0.93, blue: 0.88)
    static let subtitle = Color(red: 0.78, green: 0.72, blue: 0.64).opacity(0.85)
    static let highlightFill = Color(red: 0.095, green: 0.078, blue: 0.064)
}

// MARK: - Set Weight View

/// Requires iOS 17+ (uses scrollPosition / scrollTransition).
struct SetWeightView: View {
    var range: ClosedRange<Int> = 1...100
    var onContinue: (Int) -> Void = { _ in }

    @State private var selection: Int? = 10

    var body: some View {
        ZStack {
            WeightPalette.background.ignoresSafeArea()
            
            // MARK: IMAGE
                        Image("highswet")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 128)             .allowsHitTesting(false)
                        

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Set your weight")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(WeightPalette.title)

                    Text("This is your starting point in lifting weights.\nYou can change it later in Settings.")
                        .font(.system(size: 13))
                        .lineSpacing(3)
                        .foregroundStyle(WeightPalette.subtitle)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer(minLength: 0)

                WeightWheelPicker(range: range, selection: $selection)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                HStack {
                    Spacer()
                    WeightPageDots(count: 3, current: 2)
                    Spacer()
                }
                .padding(.bottom, 28)

                Button {
                    onContinue(selection ?? 10)
                } label: {
                    Text("Set")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(WeightPalette.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(WeightPalette.gold, in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Wheel Picker

private struct WeightWheelPicker: View {
    let range: ClosedRange<Int>
    @Binding var selection: Int?

    private let itemHeight: CGFloat = 52
    private let visibleRows: CGFloat = 5

    var body: some View {
        let height = itemHeight * visibleRows

        ZStack {
            // Highlight box behind the selected value
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(WeightPalette.highlightFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(WeightPalette.gold.opacity(0.75), lineWidth: 1.2)
                )
                .frame(height: 80)
                .padding(.horizontal, 16)

            // Scrolling numbers
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(range), id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(WeightPalette.title)
                            .frame(maxWidth: .infinity)
                            .frame(height: itemHeight)
                            .scrollTransition(axis: .vertical) { content, phase in
                                let distance = abs(phase.value)
                                let closeness = max(0, 1 - distance / 0.35)
                                return content
                                    .opacity(max(0.15, 1 - distance * 1.6))
                                    .scaleEffect(1 + 1.1 * closeness)
                            }
                            .id(value)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.vertical, (height - itemHeight) / 2, for: .scrollContent)
            .scrollPosition(id: $selection, anchor: .center)
            .scrollTargetBehavior(.viewAligned)
            .frame(height: height)
            .sensoryFeedback(.selection, trigger: selection)

            // Unit label next to the selected number
            Text("kg")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(WeightPalette.gold)
                .offset(x: unitOffset, y: 10)
                .allowsHitTesting(false)
        }
        .frame(height: height)
    }

    private var unitOffset: CGFloat {
        let digits = CGFloat(String(selection ?? 10).count)
        return digits * 16 + 22
    }
}

// MARK: - Page Dots

private struct WeightPageDots: View {
    let count: Int
    let current: Int

    var body: some View {
       /* HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? WeightPalette.gold : Color.white.opacity(0.22))
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }*/
    }
}

// MARK: - Preview

#Preview {
    SetWeightView()
}
