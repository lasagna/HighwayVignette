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

private enum AppRoute: Hashable {
    case vignetteFlow
}

private struct AppEntryView: View {
    let apiClient: HighwayAPIClient

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                Button {
                    path.append(AppRoute.vignetteFlow)
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
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .vignetteFlow:
                    VignetteSelectorView(
                        apiClient: apiClient,
                        onFinish: { path = NavigationPath() }
                    )
                }
            }
        }
    }
}
