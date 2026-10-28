import SwiftUI

// The Watch colors (qRingTrack, qGoldLight, qGoldDeep, qVioletLight, qVioletDeep, qMountain) are
// created by Xcode from the asset names. Do NOT declare them again here, or Xcode says
// "Invalid redeclaration". Only the gradients are written by hand.

extension LinearGradient {
    static let qGoldGradient = LinearGradient(
        colors: [Color.qGoldLight, Color.qGoldDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let qVioletGradient = LinearGradient(
        colors: [Color.qVioletLight, Color.qVioletDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
}
