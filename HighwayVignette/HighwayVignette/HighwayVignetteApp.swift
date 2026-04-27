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
            VignetteSelectorView(apiClient: apiClient)
        }
    }
}
