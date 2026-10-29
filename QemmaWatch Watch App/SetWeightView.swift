//
//  SetWeightView.swift
//  QemmaWatch Watch App
//
//  Created by Leen Alharbi on 15/05/1448 AH.
//

import SwiftUI

struct SetWeightView: View {
    @State private var weight = 3
    @AppStorage("currentWeight") private var storedWeight = 8
    @State private var showStart = false
     

    var body: some View {
        VStack(spacing: 4) {
            Text("Weight")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .offset(y: -8)

            HStack(spacing: 12) {
                Picker("Weight", selection: $weight) {
                    ForEach(3...50, id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: 25,weight: .bold, design: .rounded))
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(width: 100, height: 110)
                .focusEffectDisabled()
                
                

                Text("kg")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }

            Button {
                showStart = true
                storedWeight = weight
                showStart = true
            } label: {
                Text("Set!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 40)
                    .background(Color("QGold"), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding(.horizontal)
        .padding(.horizontal)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showStart) {
            StartView()
        }
        
    }
}

#Preview {
    SetWeightView()
}

