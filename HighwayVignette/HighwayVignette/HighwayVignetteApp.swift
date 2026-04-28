//
//  HighwayVignetteApp.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 24..
//

import SwiftUI

@main
struct HighwayVignetteApp: App {
    private let apiClient = HighwayAPIClient(
        baseURL: URL(string: "http://0.0.0.0:8080")!
    )

    var body: some Scene {
        WindowGroup {
            AppEntryView(apiClient: apiClient)
        }
    }
}

private struct AppEntryView: View {
    let apiClient: HighwayAPIClient

    @State private var shouldNavigateToVignetteFlow = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                Button {
                    shouldNavigateToVignetteFlow = true
                } label: {
                    Text("E-matrica")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 180, minHeight: 56)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.03, green: 0.17, blue: 0.29))
                        )
                }
                .buttonStyle(.plain)
            }
            .navigationDestination(isPresented: $shouldNavigateToVignetteFlow) {
                VignetteSelectorView(
                    apiClient: apiClient,
                    onFinish: { shouldNavigateToVignetteFlow = false }
                )
            }
        }
    }
}
