//
//  NextLevelView.swift
//  QemmaWatch Watch App
//
//  Created by Leen Alharbi on 16/05/1448 AH.
//
import SwiftUI

struct NextLevelView: View {
    var weight: Int = 8                 // the weight the user worked on in this level
    var onAccept: () -> Void = {}

    @AppStorage("currentWeight") private var storedWeight = 8
    @AppStorage("currentLevel") private var level = 1

    // Replace with the exact hex from Sketch
    private let buttonColor = Color(red: 0.37, green: 0.29, blue: 0.45)

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { geo in
                let scale = geo.size.width / 208

                Text("Level UP !")
                    .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                    .position(x: 104 * scale, y: 40 * scale)

                Image("Character")
                    .resizable()
                    .frame(width: 150 * scale, height: 80 * scale)
                    .position(x: 103 * scale, y: 115 * scale)

                Button {
                    storedWeight = weight + 1   // the new weight for the whole app
                    level += 1                  // the new level
                    onAccept()                  // go back to the Start screen
                } label: {
                    HStack(spacing: 8) {
                        Text("\(weight) kg")
                        Image(systemName: "arrow.right")
                        Text("\(weight + 1) kg")
                    }
                    .font(.system(size: 22 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 154 * scale, height: 44 * scale)
                    .background(buttonColor, in: Capsule())
                }
                .buttonStyle(.plain)
                .position(x: 104 * scale, y: 191 * scale)
            }
            .ignoresSafeArea()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NextLevelView()
}
