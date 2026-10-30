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
        PlanEditorView(plan: $plan, onStart: { connectivity.startOnWatch(plan: plan) },
                       status: connectivity.status)
            .onReceive(connectivity.$suggestedPlan.compactMap { $0 }) { plan = $0 }
    }
}

#Preview {
    ContentView()
}
