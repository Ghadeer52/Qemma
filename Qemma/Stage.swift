import SwiftUI

// MARK: - XP

struct XPProgress {
    let current: Int
    let total: Int

    var fraction: Double { total > 0 ? Double(current) / Double(total) : 0 }

    /// "380 / 1,000 XP" (بأرقام إنجليزية ثابتة حتى لو لغة الجوال عربية)
    var label: String {
        let locale = Locale(identifier: "en_US")
        let c = current.formatted(.number.locale(locale))
        let t = total.formatted(.number.locale(locale))
        return "\(c) / \(t) XP"
    }
}

// MARK: - Stage (مرحلة على الخريطة)

struct Stage: Identifiable {
    enum State { case completed, current, locked }

    let id = UUID()
    let name: String
    let altitude: String
    let level: Int
    let state: State

    // اختياري: لها قيم افتراضية، تكتب بس اللي تحتاجه (بنفس الترتيب)
    var region = ""
    var imageName = ""
    var xp: XPProgress?
    var weight = ""
    var duration = ""
    var workoutTime = ""
    var lockedMessage = ""
}

extension Stage {
    var statusText: String {
        switch state {
        case .completed: return "Reached"
        case .current:   return "In progress"
        case .locked:    return "Locked"
        }
    }

    var summaryLine: String { "\(altitude) · Level \(level) · \(statusText)" }
    var durationTitle: String { state == .current ? "Climbing for" : "Duration" }
    var mapCaption: String { state == .current ? "\(altitude) · you are here" : altitude }
    var accent: Color { state == .current ? Color.qVioletLight : Color.qGoldLight }
}

// MARK: - بيانات تجريبية (بدّلها ببياناتك الحقيقية)

extension Stage {
    static let uhud = Stage(
        name: "Mount Uhud", altitude: "1,077 m", level: 1, state: .completed,
        region: "North of Madinah", imageName: "photo3",
        weight: "9 kg", duration: "12 days", workoutTime: "3 h 40 min"
    )

    static let lawz = Stage(
        name: "Jabal Al-Lawz", altitude: "2,580 m", level: 2, state: .current,
        region: "Tabuk Province", imageName: "Image 1",
        xp: XPProgress(current: 380, total: 1000),
        weight: "10 kg", duration: "5 days", workoutTime: "1 h 20 min"
    )

    static let locked1 = Stage(
        name: "Locked", altitude: "", level: 3, state: .locked,
        imageName: "LockedMountain",
        lockedMessage: "Reach the summit of Jabal Al-Lawz to unlock this mountain."
    )

    static let locked2 = Stage(
        name: "Locked", altitude: "", level: 4, state: .locked,
        imageName: "LockedMountain",
        lockedMessage: "Reach Level 4 to unlock this mountain."
    )
}

// MARK: - XPBar (مشترك بين الهيدر والكرت)

struct XPBar: View {
    let fraction: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.qRingTrack)
                Capsule()
                    .fill(Color.qViolet)
                    .frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("XP progress")
        .accessibilityValue("\(Int(fraction * 100)) percent")
    }
}
