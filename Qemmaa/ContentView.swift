//
//  ContentView.swift
//  Qemmaa
//
//  Created by Ghadeer on 26/10/2026.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var connectivity = PhoneConnectivityManager()
    @State private var plan = WorkoutPlan(repsPerSet: [10, 9, 8])
    var body: some View {
        PlanEditorView(plan: $plan) { connectivity.send(plan: plan) }
            .onReceive(connectivity.$suggestedPlan.compactMap { $0 }) { plan = $0 }
    }
}

#Preview {
    ContentView()
}
