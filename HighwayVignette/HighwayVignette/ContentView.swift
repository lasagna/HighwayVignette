//
//  ContentView.swift
//  HighwayVignette
//
//  Created by Gergo Gombar on 2026. 04. 24..
//

import SwiftUI

struct ContentView: View {
    let apiClient: HighwayAPIClient

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Highway Vignette")
        }
        .padding()
    }
}

#Preview {
    ContentView(
        apiClient: HighwayAPIClient(baseURL: URL(string: "http://0.0.0.0:8080")!)
    )
}
