import SwiftUI

// Extra colors used by the Watch design (rings, gradients, mountains).
extension Color {
    /// #1C1815
    static let qRingTrack = Color("QRingTrack")
    /// #F1D9A6
    static let qGoldLight = Color("QGoldLight")
    /// #B88A4A
    static let qGoldDeep = Color("QGoldDeep")
    /// #CDB4EA
    static let qVioletLight = Color("QVioletLight")
    /// #8E6BB0
    static let qVioletDeep = Color("QVioletDeep")
    /// #1E1814
    static let qMountain = Color("QMountain")
}

extension LinearGradient {
    static let qGoldGradient = LinearGradient(
        colors: [.qGoldLight, .qGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let qVioletGradient = LinearGradient(
        colors: [.qVioletLight, .qVioletDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
}
