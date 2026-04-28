//
//  VignettePurchaseSuccessView.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 27..
//

import SwiftUI

struct VignettePurchaseSuccessView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("A matricákat sikeresen kifizetted.")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color(red: 0.05, green: 0.18, blue: 0.30))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button {
                    onFinish()
                } label: {
                    Text("Rendben")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.03, green: 0.17, blue: 0.29))
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    VignettePurchaseSuccessView(onFinish: {})
}
