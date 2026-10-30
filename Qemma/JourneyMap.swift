import SwiftUI

// MARK: - الشاشة الرئيسية (الخريطة)

struct JourneyMap: View {
    var level = 2
    var xp = XPProgress(current: 380, total: 1000)

    var body: some View {
        ZStack {
            Color.qBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 5) {
                header

                ClimbMap()
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)

                startButton
            }
            .padding(.horizontal, 24)
            
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("YOUR CLIMB")
                .font(.system(size: 13))
                .foregroundStyle(Color.qMuted)

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text("Level \(level)")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.qText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(xp.label)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.qVioletLight)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            XPBar(fraction: xp.fraction)
        }.padding(.horizontal, 20)
    }

    private var startButton: some View {
        Button {
            //showPlanEditor = true
        } label: {
            Text("Start Workout")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.qBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.qGold, in: Capsule())
                
        }.padding(.horizontal, 20).padding(.bottom, 40)
    }
}

// MARK: - الخريطة

private struct MapNode: Identifiable {
    enum Side { case left, right }   // مكان النص بالنسبة للنقطة

    let id = UUID()
    let stage: Stage
    let point: CGPoint
    var labelSide: Side?
}

struct ClimbMap: View {
    @State private var selectedStage: Stage?

    private let startPoint = CGPoint(x: 196, y: 539)

    private let nodes: [MapNode] = [
        MapNode(stage: .uhud,    point: CGPoint(x: 116, y: 450), labelSide: .right),
        MapNode(stage: .lawz,    point: CGPoint(x: 275, y: 317), labelSide: .left),
        MapNode(stage: .locked1, point: CGPoint(x: 146, y: 199)),
        MapNode(stage: .locked2, point: CGPoint(x: 266, y: 88))
    ]

    var body: some View {
        ZStack {
            ContourLines()
            trails
            startMarker

            ForEach(nodes) { node in
                Button {
                    selectedStage = node.stage
                } label: {
                    StageMarker(state: node.stage.state)
                        .frame(minWidth: 44, minHeight: 44)   // منطقة لمس مريحة
                        .contentShape(Circle())
                }
                .buttonStyle(BounceButtonStyle())
                .accessibilityLabel(node.stage.name)
                .position(node.point)

                if let side = node.labelSide {
                    MapCaption(stage: node.stage, alignsRight: side == .right)
                        .position(x: node.point.x + (side == .right ? 116 : -116),
                                  y: node.point.y)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(width: 402, height: 580)
        .sheet(item: $selectedStage) { stage in
            StageDetailSheet(stage: stage)
        }
    }

    // المسارات: المتبقي (باهت) والمنجز
    private var trails: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 275, y: 317))
                p.addCurve(to: CGPoint(x: 146, y: 199),
                           control1: CGPoint(x: 275, y: 258),
                           control2: CGPoint(x: 146, y: 258))
                p.addCurve(to: CGPoint(x: 266, y: 88),
                           control1: CGPoint(x: 146, y: 144),
                           control2: CGPoint(x: 266, y: 144))
            }
            .stroke(Color.qGoldDeep, lineWidth: 3)

            Path { p in
                p.move(to: startPoint)
                p.addCurve(to: CGPoint(x: 116, y: 450),
                           control1: CGPoint(x: 196, y: 495),
                           control2: CGPoint(x: 116, y: 495))
                p.addCurve(to: CGPoint(x: 275, y: 317),
                           control1: CGPoint(x: 116, y: 384),
                           control2: CGPoint(x: 275, y: 384))
            }
            .stroke(Color.qGold, lineWidth: 4)
        }
    }

    private var startMarker: some View {
        ZStack {
            Circle()
                .fill(Color.qGold)
                .frame(width: 12, height: 12)
                .position(startPoint)

            Text("Start")
                .font(.system(size: 12))
                .foregroundStyle(Color.qMuted)
                .position(x: 223, y: startPoint.y)
        }
        .allowsHitTesting(false)
    }
}
// MARK: - NEW: ستايل الحركة (يصغّر عند الضغط ويرجع بنطّة ناعمة)

private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.45),
                       value: configuration.isPressed)
    }
}

// MARK: - شكل النقطة حسب الحالة

struct StageMarker: View {
    let state: Stage.State

    var body: some View {
        switch state {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.qGold)
                .background(Circle().fill(Color.qBackground))

        case .current:
            ZStack {
                Circle().fill(Color.qVioletDeep.opacity(0.4))
                            .frame(width: 55, height: 68)

                        Image("hi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56)
                            .offset(x: 6.5)
                            .accessibilityHidden(true)
            }

        case .locked:
            ZStack {
                Circle()
                    .fill(Color.qIconCircle)
                    .overlay(Circle().stroke(Color.qMuted.opacity(0.4), lineWidth: 1.5))
                    .frame(width: 32, height: 32)
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.qMuted)
            }
        }
    }
}

// MARK: - نص بجانب النقطة

private struct MapCaption: View {
    let stage: Stage
    let alignsRight: Bool

    var body: some View {
        VStack(alignment: alignsRight ? .leading : .trailing, spacing: 2) {
            Text(stage.name)
                .foregroundStyle(Color.qText)
            Text(stage.mapCaption)
                .font(.system(size: 12))
                .foregroundStyle(stage.state == .current ? Color.qVioletLight : Color.qMuted)
        }
        .frame(width: 160, alignment: alignsRight ? .leading : .trailing)
    }
}

// MARK: - خطوط الكنتور

private struct ContourGroup {
    let center: CGPoint
    let sizes: [CGSize]   // من الأكبر إلى الأصغر
}

struct ContourLines: View {
    private let groups: [ContourGroup] = [
        ContourGroup(center: CGPoint(x: 265, y: 88),
                     sizes: [CGSize(width: 320, height: 170),
                             CGSize(width: 230, height: 120),
                             CGSize(width: 130, height: 70)]),
        ContourGroup(center: CGPoint(x: 275, y: 320),
                     sizes: [CGSize(width: 330, height: 270),
                             CGSize(width: 200, height: 150),
                             CGSize(width: 95,  height: 70)]),
        ContourGroup(center: CGPoint(x: 115, y: 450),
                     sizes: [CGSize(width: 256, height: 150),
                             CGSize(width: 150, height: 90),
                             CGSize(width: 60,  height: 40)])
    ]

    var body: some View {
        ZStack {
            ForEach(groups.indices, id: \.self) { g in
                ForEach(groups[g].sizes.indices, id: \.self) { i in
                    Ellipse()
                        .stroke(Color.qMountain, lineWidth: 1)
                        .frame(width: groups[g].sizes[i].width,
                               height: groups[g].sizes[i].height)
                        .position(groups[g].center)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    JourneyMap()
}
